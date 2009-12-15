require 'spqr/spqr'
require 'rhubarb/rhubarb'

require 'mrg/grid/config/Group'
require 'mrg/grid/config/QmfUtils'

module Mrg
  module Grid
    module Config
      class Node
        include ::Rhubarb::Persisting
        include ::SPQR::Manageable

        qmf_package_name 'mrg.grid.config'
        qmf_class_name 'Node'
        ### Property method declarations
        # property name sstr 

        declare_column :name, :string, :not_null
        declare_index_on :name

        declare_column :idgroup, :integer, references(Group)
        
        qmf_property :name, :sstr, :index=>true
        ### Schema method declarations
        
        # GetPool 
        # * pool (sstr/O)
        def GetPool()
          # Assign values to output parameters
          pool ||= ""
          # Return value
          return pool
        end
        
        expose :GetPool do |args|
          args.declare :pool, :sstr, :out, {}
        end
        
        # SetPool 
        # * pool (sstr/I)
        def SetPool(pool)
          # Print values of input parameters
          log.debug "SetPool: pool => #{pool}"
        end
        
        expose :SetPool do |args|
          args.declare :pool, :sstr, :in, {}
        end
        
        # GetLastCheckinTime 
        # * time (uint32/O)
        def GetLastCheckinTime()
          # Assign values to output parameters
          time ||= 0
          # Return value
          return time
        end
        
        expose :GetLastCheckinTime do |args|
          args.declare :time, :uint32, :out, {}
        end
        
        # GetConfig 
        # * config (map/O)
        #   A map(parameter, value) representing the configuration for the node supplied
        def GetConfig()
          config = {}

          memberships.reverse_each do |grp|
            # FIXME: apply configuration for each feature in this group
          end

          return config
        end
        
        expose :GetConfig do |args|
          args.declare :config, :map, :out, {}
        end
        
        # CheckConfigVersion 
        # * version (uint32/I)
        def CheckConfigVersion(version)
          # Print values of input parameters
          log.debug "CheckConfigVersion: version => #{version}"
        end
        
        expose :CheckConfigVersion do |args|
          args.declare :version, :uint32, :in, {}
        end
        
        def GetIdentityGroup
          log.debug "GetIdentityGroup called"
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
        def ModifyMemberships(command,groups,options)
          # Print values of input parameters
          log.debug "ModifyMemberships: command => #{command}"
          log.debug "ModifyMemberships: nodes => #{nodes}"
          log.debug "ModifyMemberships: options => #{options}"
          
          groups = grps.sort {|a,b| a[0] <=> b[0]}.map {|t| t[1]}.map do |gn|
            group = Group.find_first_by_name(gn)
            raise "invalid parameter #{gn}" unless group
            group
          end

          case command
          when "ADD", "REMOVE" then
            groups.each do |grow|
              gn = grow.name

              # Delete any prior mappings for each supplied grp in either case
              NodeMembership.find_by(:node=>self, :grp=>grow).map {|nm| nm.delete unless nm.grp.is_identity_group}

              # Add new mappings when requested
              NodeMembership.create(:node=>self, :grp=>grow, :value=>pvmap[gn]) if command == "ADD"
            end
          when "REPLACE"
            memberships.map {|nm| nm.delete}

            groups.each do |grow|
              gn = grow.name

              NodeMembership.create(:node=>self, :grp=>grow, :value=>pvmap[gn])
            end
          end
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
          FakeList[*memberships.map{|g| g.name}]
        end
        
        expose :GetMemberships do |args|
          args.declare :groups, :map, :out, {}
        end
        
        private
        def idgroupname
          "+++#{Digest::MD5.hexdigest(self.name)}"
        end
        
        def id_group_init
          ig = Group.create(:name=>idgroupname, :is_identity_group=>true)
          NodeMembership.create(:node=>self, :grp=>ig)
          ig
        end
        
        def memberships
          NodeMembership.find_by(:node=>self, :is_identity_group=>false).map{|nm| nm.grp}
        end
      end
      
      class NodeMembership
        include ::Rhubarb::Persisting
        declare_column :node, :integer, references(Node, :on_delete=>:cascade)
        declare_column :grp, :integer, references(Group, :on_delete=>:cascade)
      end
    end
  end
end
