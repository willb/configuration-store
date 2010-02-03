require 'spqr/spqr'
require 'rhubarb/rhubarb'

require 'mrg/grid/config/Group'
require 'mrg/grid/config/QmfUtils'

module Mrg
  module Grid
    module Config

      # forward declaration
      class Group
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
        
        qmf_property :name, :sstr, :index=>true
        ### Schema method declarations
        
        # GetPool 
        # * pool (sstr/O)
        def GetPool()
          log.debug "GetPool called on node #{self.inspect}"
          # Return value
          return self.pool
        end
        
        expose :GetPool do |args|
          args.declare :pool, :sstr, :out, {}
        end
        
        # SetPool 
        # * pool (sstr/I)
        def SetPool(pool)
          # Print values of input parameters
          log.debug "SetPool: pool => #{pool.inspect}"
          self.pool = pool
        end
        
        expose :SetPool do |args|
          args.declare :pool, :sstr, :in, {}
        end
        
        # GetLastCheckinTime 
        # * time (uint32/O)
        def GetLastCheckinTime()
          log.debug "GetLastCheckinTime called on node #{self.inspect}"
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
          log.debug "GetConfig called on node #{self.inspect}"
          config = {}

          memberships.reverse_each do |grp|
            # apply each feature
            grp.features.reverse_each do |feature|
              log.debug("applying config for #{feature.name}")
              config = feature.apply_to(config)
              log.debug("config is #{config.inspect}")
            end
            
            # apply group-specific param settings
            grp.params.each do |k,v|
              log.debug("applying config params #{k.inspect} --> #{v.inspect}")
              config[k] = v
              log.debug("config is #{config.inspect}")
            end
          end

          log.debug("self.idgroup --> #{self.idgroup.name}")
          log.debug("#{self.idgroup.name} has #{self.idgroup.features.size} features")

          self.idgroup.features.reverse_each do |feature|
            log.debug("applying config for #{feature.name}")
            config = feature.apply_to(config)
            log.debug("config is #{config.inspect}")
          end

          log.debug("#{self.idgroup.name} has #{self.idgroup.params.size} params")
          # apply group-specific param settings
          self.idgroup.params.each do |k,v|
            log.debug("applying config params #{k.inspect} --> #{v.inspect}")
            config[k] = v
            log.debug("config is #{config.inspect}")
          end

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
            raise "Invalid group #{gn}" unless group
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

        def GetMembershipsAsString()
          log.debug "GetMembershipsAsString called on node #{self.inspect}"
          ls = memberships.map{|g| g.name}
          ls << idgroupname
          ls.inspect
        end
        
        expose :GetMembershipsAsString do |args|
          args.declare :groups, :lstr, :out, {}
        end
        
        def GetConfigAsString
          log.debug "GetConfigAsString called on node #{self.inspect}"
          hash = self.GetConfig
          "{"+hash.map{|pair| "#{pair[0].inspect}:#{pair[1].inspect}"}.join(",")+"}"
        end
        
        expose :GetConfigAsString do |args|
          args.declare :config_hash, :lstr, :out, {}
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
          NodeMembership.find_by(:node=>self).map{|nm| nm.grp}.select {|g| not g.is_identity_group}
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
