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
require 'mrg/grid/config/QmfUtils'
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
      
      class Node
        include ::Rhubarb::Persisting
        include ::SPQR::Manageable
        include DataValidating
        include ConfigValidating

        qmf_package_name 'mrg.grid.config'
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
          log.debug "last_updated_version called for #{self}; its value is #{orig_last_checkin.inspect}"
          orig_last_updated_version || 0
        end

        qmf_property :name, :sstr, :index=>true
        qmf_property :provisioned, :bool
        qmf_property :last_checkin, :uint64
        qmf_property :last_updated_version, :uint64

        ### Schema method declarations
        
        [:MakeProvisioned, :MakeUnprovisioned].each do |name|
          define_method name do
            log.debug "#{name} called on #{self}"
            self.provisioned = (name == :MakeProvisioned)
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
        
        # getLastCheckinTime 
        # * time (uint32/O)
        def getLastCheckinTime()
          log.debug "getLastCheckinTime called on node #{self.inspect}"
          # Assign values to output parameters
          self.last_checkin ||= 0
          # Return value
          return self.last_checkin
        end
        
        expose :getLastCheckinTime do |args|
          args.declare :time, :uint64, :out, {}
        end
        
        # getConfig 
        # * config (map/O)
        #   A map(parameter, value) representing the configuration for the node supplied
        def getConfig()
          log.debug "getConfig called on node #{self.inspect}"
          config = Group.DEFAULT_GROUP.getConfig
          # strip StringSet markers from default group config
          config.each do |(k,v)|
            v.slice!(/^>=/) if v
            config[k] = v && v.strip
          end
          
          log.debug "Starting with DEFAULT_GROUP config, which is #{config.inspect}"

          memberships.reverse_each do |grp|
            log.debug("#{self.name} is a member of #{grp.name}")
            log.debug("#{grp.name} has #{grp.features.size} features")
            
            config = grp.apply_to(config)
          end

          config = self.idgroup.apply_to(config) if self.idgroup

          # XXX: this will change once we have configuration versioning
          config["WALLABY_CONFIG_VERSION"] = self.last_updated_version.to_s
          
          config
        end
        
        expose :getConfig do |args|
          args.declare :config, :map, :out, {}
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
        
        def getIdentityGroup
          log.debug "getIdentityGroup called on node #{self.inspect}"
          self.idgroup ||= id_group_init
          self.idgroup
        end

        expose :getIdentityGroup do |args|
          args.declare :group, :objId, :out, {}
        end
        
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
            memberships.map {|nm| nm.delete}

            groups.each do |grow|
              gn = grow.name

              NodeMembership.create(:node=>self, :grp=>grow)
            end
          else fail(Errors.make(Errors::INVALID_COMMAND), "Invalid command #{command}")
          end
          
          DirtyElement.dirty_node(self)
        end
        
        expose :modifyMemberships do |args|
          args.declare :command, :sstr, :in, {}
          args.declare :groups, :list, :in, {}
          args.declare :options, :map, :in, {}
        end
        
        # getMemberships 
        # * list (map/O)
        #   A list of the groups associated with this node, in inverse priority order (most important first), not including the identity group
        def getMemberships()
          log.debug "getMemberships called on node #{self.inspect}"
          memberships.map {|g| g.name}
        end
        
        expose :getMemberships do |args|
          args.declare :groups, :list, :out, {}
        end
        
        def Node.get_dirty_nodes
          return Node.find_all() if DirtyElement.find_first_by_kind(DirtyElement.const_get("KIND_EVERYTHING"))
          return Node.find_all() if DirtyElement.find_by(:kind=>DirtyElement.const_get("KIND_GROUP"), :grp=>Group.DEFAULT_GROUP)
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
          [Group.DEFAULT_GROUP] + memberships + [self.getIdentityGroup]
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
        
        def memberships
          NodeMembership.find_by(:node=>self).map{|nm| nm.grp}.select {|g| not g.is_identity_group}
        end
      end
    end
  end
end
