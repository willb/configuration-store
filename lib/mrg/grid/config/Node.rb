# Node:  QMF node entity
#
# Copyright (c) 2009--2010 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.require 'spqr/spqr'
require 'rhubarb/rhubarb'

require 'mrg/grid/config/Group'
require 'mrg/grid/config/DataValidating'
require 'mrg/grid/config/ConfigValidating'

module Mrg
  module Grid
    module Config

      # forward declarations
      class NodeMembership
      end
      
      class Store
      end
      
      class DirtyElement
      end
      
      class ConfigVersion
      end
      
      module ReconfigEventMapBuilder
      end
      
      class Node
        include ::Rhubarb::Persisting
        include ::SPQR::Manageable
        include DataValidating
        include ConfigValidating

        qmf_package_name 'com.redhat.grid.config'
        qmf_class_name 'Node'
        ### Property method declarations
        # property name sstr 

        declare_column :name, :string, :not_null
        declare_index_on :name

        declare_column :pool, :string

        declare_column :idgroup, :integer, references(Group)
        
        declare_column :provisioned, :boolean, :default, :true
        declare_column :last_checkin, :integer
        declare_column :last_updated_version, :integer

        alias orig_provisioned provisioned
        alias orig_last_checkin last_checkin

        alias orig_last_updated_version last_updated_version

        def provisioned
          log.debug "provisioned called for #{self}; its value is #{orig_provisioned.inspect}"
          orig_provisioned
        end
        
        def last_checkin
          log.debug "last_checkin called for #{self}; its value is #{orig_last_checkin.inspect}"
          orig_last_checkin || 0
        end

        def last_updated_version
          log.debug "last_updated_version called for #{self}; its value is #{orig_last_updated_version.inspect}"
          orig_last_updated_version || 0
        end

        qmf_property :name, :sstr, :index=>true
        qmf_property :provisioned, :bool
        qmf_property :last_checkin, :uint64
        qmf_property :last_updated_version, :uint64

        ### Schema method declarations
        
        [:makeProvisioned, :makeUnprovisioned].each do |name|
          define_method name do
            log.debug "#{name} called on #{self}"
            self.provisioned = (name == :makeProvisioned)
            # NB: these don't change the dirty status of this node
          end
          
          expose name do |args| ; end
        end
        
        def checkin()
          log.debug "node #{self.inspect} checking in"
          self.last_checkin = ::Rhubarb::Util::timestamp
        end
        
        expose :checkin do |args|
        end
        
        # getConfig 
        # * options (map/I)
        # * config (map/O)
        #   A map(parameter, value) representing the configuration for the node supplied
        def getConfig(options=nil)
          options ||= {}
          return getCurrentConfig unless options["version"]
          ConfigVersion.getVersionedNodeConfig(self.name, options["version"]) || {}
        end
        
        expose :getConfig do |args|
          args.declare :options, :map, :in, "Valid options include 'version', which maps to a version number.  If this is supplied, return the latest version not newer than 'version'."
          args.declare :config, :map, :out, "A map from parameter names to values representing the configuration for this node."
        end
        
        def getCurrentConfig
          log.debug "getConfig called on node #{self.inspect}"
          config = Group.DEFAULT_GROUP.getConfig
          # strip StringSet markers from default group config
          config.each do |(k,v)|
            v.slice!(/^>=/) if v
            config[k] = v && v.strip
          end
          
          log.debug "Starting with DEFAULT_GROUP config, which is #{config.inspect}"

          db_memberships.reverse_each do |grp|
            log.debug("#{self.name} is a member of #{grp.name}")
            log.debug("#{grp.name} has #{grp.features.size} features")
            
            config = grp.apply_to(config)
          end

          config = self.idgroup.apply_to(config) if self.idgroup

          # XXX: this will change once we have configuration versioning
          config["WALLABY_CONFIG_VERSION"] = self.last_updated_version.to_s
          
          config
        end
        
        # checkConfigVersion 
        # * version (uint32/I)
        def checkConfigVersion(version)
          # Print values of input parameters
          log.debug "checkConfigVersion: version => #{version.inspect}"
        end
        
        expose :checkConfigVersion do |args|
          args.declare :version, :uint32, :in, {}
        end
        
        def identity_group
          log.debug "identity_group called on node #{self.inspect}"
          self.idgroup ||= id_group_init
          self.idgroup
        end

        qmf_property :identity_group, :objId, :desc=>"The object ID of this node's identity group."
        
        # modifyMemberships
        # * command (sstr/I)
        #   Valid commands are 'ADD', 'REMOVE', and 'REPLACE'.
        # * groups (list/I)
        #   A list of groups, in inverse priority order (most important first)
        # * options (map/I)
        def modifyMemberships(command,groups,options={})
          # Print values of input parameters
          log.debug "modifyMemberships: command => #{command.inspect}"
          log.debug "modifyMemberships: groups => #{groups.inspect}"
          log.debug "modifyMemberships: options => #{options.inspect}"
          
          invalid_groups = []
          
          groups = groups.map do |gn|
            group = Group.find_first_by_name(gn)
            invalid_groups << gn unless group
            group
          end

          fail(Errors.make(Errors::NONEXISTENT_ENTITY, Errors::GROUP), "Invalid groups for node #{self.name}: #{gn.inspect}") if invalid_groups != []

          command = command.upcase

          case command
          when "ADD", "REMOVE" then
            groups.each do |grow|
              gn = grow.name

              # Delete any prior mappings for each supplied grp in either case
              NodeMembership.find_by(:node=>self, :grp=>grow).map {|nm| nm.delete unless nm.grp.is_identity_group}

              # Add new mappings when requested
              NodeMembership.create(:node=>self, :grp=>grow) if command == "ADD"
            end
          when "REPLACE" then
            NodeMembership.find_by(:node=>self).map {|nm| nm.delete unless nm.grp.is_identity_group}

            groups.each do |grow|
              gn = grow.name

              NodeMembership.create(:node=>self, :grp=>grow)
            end
          else fail(Errors.make(Errors::INVALID_COMMAND), "Invalid command #{command}")
          end
          
          DirtyElement.dirty_node(self)
        end
        
        expose :modifyMemberships do |args|
          args.declare :command, :sstr, :in, "Valid commands are 'ADD', 'REMOVE', and 'REPLACE'."
          args.declare :groups, :list, :in, "A list of groups, in inverse priority order (most important first)."
          args.declare :options, :map, :in, "No options are supported at this time."
        end
        
        # memberships 
        # * list (map/O)
        #   A list of the groups associated with this node, in inverse priority order (most important first), not including the identity group
        def memberships()
          log.debug "memberships called on node #{self.inspect}"
          db_memberships.map {|g| g.name}
        end
        
        qmf_property :memberships, :list, :desc=>"A list of the groups associated with this node, in inverse priority order (most important first), not including the identity group."

        def whatChanged(old_version, new_version)
          node_params = {self.name => ConfigVersion.whatchanged(self.name, old_version, new_version)}
          rem = ReconfigEventMapBuilder.build(node_params)
          [node_params[self.name], rem.restart.keys, rem.reconfig.keys]
        end
        
        expose :whatChanged do |args|
          args.declare :old_version, :uint64, :in, "The old version."
          args.declare :new_version, :uint64, :in, "The new version."
          args.declare :params, :list, :out, "A list of parameters whose values changed between old_version and new_version."
          args.declare :restart, :list, :out, "A list of subsystems that must be restarted as a result of the changes between old_version and new_version."
          args.declare :affected, :list, :out, "A list of subsystems that must re-read their configurations as a result of the changes between old_version and new_version."
        end
        
        def Node.get_dirty_nodes
          return Node.find_all() if DirtyElement.find_by(:kind=>DirtyElement.const_get("KIND_EVERYTHING")).size > 0
          return Node.find_all() if DirtyElement.find_by(:kind=>DirtyElement.const_get("KIND_GROUP"), :grp=>Group.DEFAULT_GROUP).size > 0
          Node._get_dirty_nodes
        end
        
        declare_custom_query :_get_dirty_nodes, <<-QUERY
SELECT * FROM __TABLE__ WHERE row_id IN (
  SELECT nodemembership.node AS node FROM dirtyelement JOIN nodemembership WHERE dirtyelement.grp = nodemembership.grp UNION 
  SELECT node FROM dirtyelement UNION
  SELECT nodemembership.node AS node FROM dirtyelement JOIN groupfeatures, nodemembership WHERE dirtyelement.feature = groupfeatures.feature AND nodemembership.grp = groupfeatures.grp UNION
  SELECT nodemembership.node AS node FROM dirtyelement JOIN groupparams, nodemembership WHERE dirtyelement.parameter = groupparams.param AND nodemembership.grp = groupparams.grp UNION 
  SELECT nodemembership.node AS node FROM dirtyelement JOIN groupfeatures, nodemembership WHERE dirtyelement.feature = groupfeatures.feature AND nodemembership.grp = groupfeatures.grp
)
        QUERY
        
        private
        
        def my_features
          my_groups.inject([]) do |acc, grp|
            current_features = grp.features
            acc |= grp.features
            acc
          end
        end

        def my_groups
          [Group.DEFAULT_GROUP] + db_memberships + [self.identity_group]
        end
        
        def idgroupname
          "+++#{Digest::MD5.hexdigest(self.name)}"
        end
        
        def id_group_init
          ig = Group.find_first_by_name(idgroupname)
          ig = Group.create(:name=>idgroupname, :is_identity_group=>true) unless ig
          NodeMembership.create(:node=>self, :grp=>ig) unless NodeMembership.find_by(:node=>self, :grp=>ig).size > 0
          ig
        end
        
        def db_memberships
          NodeMembership.find_by(:node=>self).map{|nm| nm.grp}.select {|g| not g.is_identity_group}
        end
      end
    end
  end
end
