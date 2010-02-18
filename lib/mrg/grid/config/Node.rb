require 'spqr/spqr'
require 'rhubarb/rhubarb'

require 'mrg/grid/config/Group'
require 'mrg/grid/config/QmfUtils'

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
        
        # GetLastCheckinTime 
        # * time (uint32/O)
        def GetLastCheckinTime()
          log.debug "GetLastCheckinTime called on node #{self.inspect}"
          # Assign values to output parameters
          self.last_checkin ||= 0
          # Return value
          return self.last_checkin
        end
        
        expose :GetLastCheckinTime do |args|
          args.declare :time, :uint32, :out, {}
        end
        
        # GetConfig 
        # * config (map/O)
        #   A map(parameter, value) representing the configuration for the node supplied
        def GetConfig()
          log.debug "GetConfig called on node #{self.inspect}"
          config = Group.DEFAULT_GROUP.GetConfig
          log.debug "Starting with DEFAULT_GROUP config, which is #{config.inspect}"

          memberships.reverse_each do |grp|
            log.debug("#{self.name} is a member of #{grp.name}")
            log.debug("#{grp.name} has #{grp.features.size} features")
            
            config = config.merge(grp.GetConfig)
          end

          config = config.merge(idgroup.GetConfig)
          
          # XXX: this will change once we have configuration versioning
          config["WALLABY_CONFIG_VERSION"] = self.last_updated_version.to_s
          
          config
        end
        
        expose :GetConfig do |args|
          args.declare :config, :map, :out, {}
        end
        
        # CheckConfigVersion 
        # * version (uint32/I)
        def CheckConfigVersion(version)
          # Print values of input parameters
          log.debug "CheckConfigVersion: version => #{version.inspect}"
        end
        
        expose :CheckConfigVersion do |args|
          args.declare :version, :uint32, :in, {}
        end
        
        def GetIdentityGroup
          log.debug "GetIdentityGroup called on node #{self.inspect}"
          self.idgroup ||= id_group_init
        end

        expose :GetIdentityGroup do |args|
          args.declare :group, :objId, :out, {}
        end
        
        # ModifyMemberships
        # * command (sstr/I)
        #   Valid commands are 'ADD', 'REMOVE', and 'REPLACE'.
        # * groups (map/I)
        #   A list of groups, in inverse priority order (most important first)
        # * options (map/I)
        def ModifyMemberships(command,groups,options={})
          # Print values of input parameters
          log.debug "ModifyMemberships: command => #{command.inspect}"
          log.debug "ModifyMemberships: groups => #{groups.inspect}"
          log.debug "ModifyMemberships: options => #{options.inspect}"
          
          groups = FakeList.normalize(groups).to_a.map do |gn|
            group = Group.find_first_by_name(gn)
            raise "Invalid group #{gn.inspect}" unless group
            group
          end

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
          else raise ArgumentError.new("invalid command #{command}")
          end
          
          DirtyElement.dirty_node(self)
        end
        
        expose :ModifyMemberships do |args|
          args.declare :command, :sstr, :in, {}
          args.declare :groups, :map, :in, {}
          args.declare :options, :map, :in, {}
        end
        
        # GetMemberships 
        # * list (map/O)
        #   A list of the groups associated with this node, in inverse priority order (most important first), not including the identity group
        def GetMemberships()
          log.debug "GetMemberships called on node #{self.inspect}"
          FakeList[*memberships.map{|g| g.name}]
        end
        
        expose :GetMemberships do |args|
          args.declare :groups, :map, :out, {}
        end
        
        # Validate ensures the following for a given node N:
        #  1.  if N enables some feature F that depends on F', N must also include F', 
        #        enable F', or enable some feature F'' that includes F'
        #  2.  if N enables some feature F that depends on some param P being set,
        #        N must provide a value for P
        #  3.  if N sets some param P that depends on some other param P',
        #        N must also set P'
        #    
        #  Other consistency properties are ensured by other parts of the store (e.g.
        #  that a group does not enable conflicting features).  Returns true if the
        #  configuration is valid, or an explanation if it is not.
        
        
        def validate
          my_config = self.GetConfig  # FIXME: it would be nice to not calculate this redundantly
          orphaned_deps = Feature.dependencies_for_node(self) - Feature.features_for_node(self)
          unset_params = my_unset_params(my_config)
          my_params = Parameter.s_for_node(self)
          my_param_deps = Parameter.dependencies_for_node(self, my_params)
          orphaned_params = my_param_deps - my_params
          
          return true if orphaned_deps == [] && unset_params == [] && orphaned_params == []
          
          result = {}
          result["Unsatisfied feature dependencies"] = orphaned_deps if orphaned_deps != []
          result["Unset necessary parameters"] = unset_params if unset_params != []
          result["Unsatisfied parameter dependencies"] = orphaned_params if orphaned_params != []
          
          [self.name, result]
        end
        
        def Node.get_dirty_nodes
          return Node.find_all() if DirtyElement.find_first_by_kind(DirtyElement.const_get("KIND_EVERYTHING"))
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
        
        def my_unset_params(my_config = nil)
          my_config ||= self.GetConfig
          mc_params = Parameter.s_that_must_change
          (my_config.keys & mc_params.keys).inject([]) do |acc,param|
            dv = Parameter.find_first_by_name(param).default_val
            acc << param if my_config[param] = dv
            acc
          end
        end
          
        def my_features
          my_groups.inject([]) do |acc, grp|
            current_features = grp.features
            acc |= grp.features
            acc
          end
        end

        def my_groups
          [Group.DEFAULT_GROUP] + memberships + [idgroup]
        end
        
        def idgroupname
          "+++#{Digest::MD5.hexdigest(self.name)}"
        end
        
        def id_group_init
          ig = Group.create(:name=>idgroupname, :is_identity_group=>true)
          NodeMembership.create(:node=>self, :grp=>ig)
          ig
        end
        
        def memberships
          NodeMembership.find_by(:node=>self).map{|nm| nm.grp}.select {|g| not g.is_identity_group}
        end
      end
    end
  end
end
