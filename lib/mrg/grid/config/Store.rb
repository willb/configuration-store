require 'spqr/spqr'

require 'mrg/grid/config-proxies'

module Mrg
  module Grid
    module Config
      class Store
        include ::SPQR::Manageable

        qmf_package_name 'mrg.grid.config'
        qmf_class_name 'Store'

        def Store.find_by_id(u)
          @singleton ||= Store.new
        end

        def Store.find_all
          @singleton ||= Store.new
          [@singleton]
        end

        ### Property method declarations
        # property APIVersionNumber uint32 The version of the API the store supports
        attr_accessor :apiVersionNumber
        qmf_property :apiVersionNumber, :uint32, :desc=>"The version of the API the store supports", :index=>false
        ### Schema method declarations
        
        def GetDefaultGroup
          return Group.DEFAULT_GROUP
        end
        
        expose :GetDefaultGroup do |args|
          args.declare :obj, :objId, :out, {}
        end
        
        # GetGroup 
        # * query (map/I)
        #   A map(queryType, value) that defines the group desired. The queryType can be either 'ID' or 'Name'. 'ID' queryTypes will search for a group with the ID defined in value. 'Name' queryTypes will search for a group with the name defined in value.
        # * obj (objId/O)
        def GetGroup(query)
          qentries = query.entries
          raise ArgumentError.new("Invalid group query #{query.inspect}") if qentries.size != 1
          qkind, qkey = query.entries.pop
          qkind = qkind.upcase
          
          case qkind
          when "ID"
            return Group.find(qkey)
          when "NAME"
            return Group.find_first_by_name(qkey)
          else raise ArgumentError.new("Invalid group query kind #{qkind}")
          end
        end
        
        expose :GetGroup do |args|
          args.declare :obj, :objId, :out, {}
          args.declare :query, :map, :in, {}
        end

        def GetGroupByName(name)
          GetGroup({"NAME"=>name})
        end
        
        expose :GetGroupByName do |args|
          args.declare :name, :sstr, :in, {}
          args.declare :obj, :objId, :out, {}
        end
        
        # AddExplicitGroup 
        # * name (sstr/I)
        # * obj (objId/O)
        def AddExplicitGroup(name)
          # Print values of input parameters
          log.debug "AddExplicitGroup: name => #{name.inspect}"
          raise "Group name #{name} is already taken" if Group.find_first_by_name(name)
          raise "Group name #{name} is invalid; group names may not start with '+++'" if name.slice(0,3) == "+++"
          Group.create(:name=>name)
        end
        
        expose :AddExplicitGroup do |args|
          args.declare :obj, :objId, :out, {}
          args.declare :name, :sstr, :in, {}
        end
        
        # RemoveGroup 
        # * uid (uint32/I)
        def RemoveGroup(uid)
          # Print values of input parameters
          log.debug "RemoveGroup: uid => #{uid.inspect}"
          Group.find(uid).delete
        end
        
        expose :RemoveGroup do |args|
          args.declare :uid, :uint32, :in, {}
        end
        
        # GetFeature 
        # * name (sstr/I)
        # * obj (objId/O)
        def GetFeature(name)
          # Print values of input parameters
          log.debug "GetFeature: name => #{name.inspect}"
          Feature.find_first_by_name(name)
        end
        
        expose :GetFeature do |args|
          args.declare :obj, :objId, :out, {}
          args.declare :name, :sstr, :in, {}
        end
        
        # AddFeature 
        # * name (sstr/I)
        # * obj (objId/O)
        def AddFeature(name)
          # Print values of input parameters
          log.debug "AddFeature: name => #{name.inspect}"
          raise "Feature name #{name} is already taken" if Feature.find_first_by_name(name)
          return Feature.create(:name=>name)
        end
        
        expose :AddFeature do |args|
          args.declare :obj, :objId, :out, {}
          args.declare :name, :sstr, :in, {}
        end
        
        # RemoveFeature 
        # * uid (uint32/I)
        def RemoveFeature(uid)
          # Print values of input parameters
          log.debug "RemoveFeature: uid => #{uid.inspect}"
          Feature.find(uid).delete
        end
        
        expose :RemoveFeature do |args|
          args.declare :uid, :uint32, :in, {}
        end
        
        # GetConfiguration 
        # * query (map/I)
        #   A query that defines the configuration desired. Valid values for the key are 'ID' or 'Name'. 'ID' keys should contain a specific ConfigurationId as its value, whereas 'Name' keys should contain a Configuration Name as its value
        # * obj (objId/O)
        def GetConfiguration(query)
          # Print values of input parameters
          log.debug "GetConfiguration: query => #{query.inspect}"
          # Assign values to output parameters
          obj ||= nil
          # Return value
          return obj
        end
        
        expose :GetConfiguration do |args|
          args.declare :obj, :objId, :out, {}
          args.declare :query, :map, :in, {}
        end
        
        # MakeSnapshot 
        # * name (sstr/I)
        #   A name for this configuration. A blank name will result in the store creating a name
        # * uid (uint32/O)
        # * params (map/O)
        #   A map (param:reasonString) containing a list of parameters and a reasonString for the parameter that must be set for the configuration to be valid
        def MakeSnapshot(name)
          # Print values of input parameters
          log.debug "MakeSnapshot: name => #{name.inspect}"
          # Assign values to output parameters
          uid ||= 0
          params ||= {}
          # Return value
          return [uid, params]
        end
        
        expose :MakeSnapshot do |args|
          args.declare :uid, :uint32, :out, {}
          args.declare :params, :map, :out, {}
          args.declare :name, :sstr, :in, {}
        end
        
        # ChangeConfiguration 
        # * uid (uint32/I)
        def ChangeConfiguration(uid)
          # Print values of input parameters
          log.debug "ChangeConfiguration: uid => #{uid.inspect}"
        end
        
        expose :ChangeConfiguration do |args|
          args.declare :uid, :uint32, :in, {}
        end
        
        # ActivateConfiguration 
        # * params (map/O)
        #   A map (param:reasonString) containing a list of parameters and a reasonString for the parameter that must be set for the configuration to be valid
        def ActivateConfiguration()
          # Assign values to output parameters
          params ||= {}
          # Return value
          return params
        end
        
        expose :ActivateConfiguration do |args|
          args.declare :params, :map, :out, {}
        end
        
        # AddNode 
        # * name (sstr/I)
        # * obj (objId/O)
        def AddNode(name)
          # Print values of input parameters
          log.debug "AddNode: name => #{name.inspect}"

          # Return a newly-created node after ensuring that its identity group is initialized
          n = Node.create(:name => name)
          n.GetIdentityGroup
          n
        end
        
        expose :AddNode do |args|
          args.declare :obj, :objId, :out, {}
          args.declare :name, :sstr, :in, {}
        end

        # GetNode 
        # * name (sstr/I)
        # * obj (objId/O)
        def GetNode(name)
          # Print values of input parameters
          log.debug "GetNode: name => #{name.inspect}"

          # Return the node with the given name
          return Node.find_first_by_name(name)
        end
        
        expose :GetNode do |args|
          args.declare :obj, :objId, :out, {}
          args.declare :name, :sstr, :in, {}
        end
        
        # RemoveNode 
        # * name (sstr/I)
        def RemoveNode(name)
          # Print values of input parameters
          log.debug "RemoveNode: name => #{name.inspect}"

          # Actually remove the node
          Node.find_first_by_name(name).delete
        end
        
        expose :RemoveNode do |args|
          args.declare :name, :sstr, :in, {}
        end
        
        # GetParam 
        # * name (sstr/I)
        # * obj (objId/O)
        #   A reference to the parameter object that matches the name supplied
        def GetParam(name)
          # Print values of input parameters
          log.debug "GetParam: name => #{name.inspect}"

          return Parameter.find_first_by_name(name)
        end
        
        expose :GetParam do |args|
          args.declare :obj, :objId, :out, {}
          args.declare :name, :sstr, :in, {}
        end
        
        # AddParam 
        # * name (sstr/I)
        # * obj (objId/O)
        #   A reference to the newly added parameter object
        def AddParam(name)
          # Print values of input parameters
          log.debug "AddParam: name => #{name.inspect}"
           raise "Parameter name #{name} is already taken" if Parameter.find_first_by_name(name)
          # Return value
          return Parameter.create(:name => name)
        end
        
        expose :AddParam do |args|
          args.declare :obj, :objId, :out, {}
          args.declare :name, :sstr, :in, {}
        end
        
        # GetSubsys 
        # * name (sstr/I)
        # * obj (objId/O)
        #   A reference to the subsystem object that matches the name supplied
        def GetSubsys(name)
          # Print values of input parameters
          log.debug "GetSubsys: name => #{name.inspect}"

          return Subsystem.find_first_by_name(name)
        end

        expose :GetSubsys do |args|
          args.declare :obj, :objId, :out, {}
          args.declare :name, :sstr, :in, {}
        end

        # AddSubsys 
        # * name (sstr/I)
        # * obj (objId/O)
        #   A reference to the newly added subsystem object
        def AddSubsys(name)
          # Print values of input parameters
          log.debug "AddSubsys: name => #{name.inspect}"
           raise "Subsystem name #{name} is already taken" if Subsystem.find_first_by_name(name)
          # Return value
          return Subsystem.create(:name => name)
        end

        expose :AddSubsys do |args|
          args.declare :obj, :objId, :out, {}
          args.declare :name, :sstr, :in, {}
        end
        
        
        # RemoveParam 
        # * name (sstr/I)
        def RemoveParam(name)
          # Print values of input parameters
          log.debug "RemoveParam: name => #{name.inspect}"
          Parameter.find_first_by_name(name).delete
        end
        
        expose :RemoveParam do |args|
          args.declare :name, :sstr, :in, {}
        end

        # RemoveSubsys 
        # * name (sstr/I)
        def RemoveSubsys(name)
          # Print values of input parameters
          log.debug "RemoveSubsys: name => #{name.inspect}"
          Subsystem.find_first_by_name(name).delete
        end

        expose :RemoveSubsys do |args|
          args.declare :name, :sstr, :in, {}
        end
        
        def storeinit(kwargs=nil)
          kwargs ||= {}
          if kwargs.keys.map {|k| k.upcase}.include? "RESETDB"
            clear_db
          end
          
          Group.DEFAULT_GROUP
          nil
        end
        
        expose :storeinit do |args|
          args.declare :options, :map, :in, {}
        end
        
        # <method name="MakeSnapshot">
        #    <arg name="name" dir="I" type="sstr"
        #         desc="A name for this configuration.  A blank name will result
        #               in the store creating a name"/>
        # </method>
        
        def MakeSnapshot(name)
          tm = Time.now.utc
          name = "Automatically generated snapshot at #{tm} -- #{((tm.tv_sec * 1000000) + tm.tv_usec).to_s(16)}" if name.size == 0
          result = Snapshot.create(:name=>name)
          snaptext = ::Mrg::Grid::SerializedConfigs::ConfigSerializer.new(self, false).serialize.to_yaml
          result.snaptext = snaptext
        end
        
        expose :MakeSnapshot do |args|
          args.declare :name, :sstr, :in, :desc=>"A name for this configuration.  A blank name will result in the store creating a name"
        end
        
        def LoadSnapshot(name)
          snap = Snapshot.find_first_by_name(name)
          
          raise "Invalid snapshot name #{name}" unless snap
          snaptext = snap.snaptext
          
          storeinit("RESETDB"=>true)
          
          ::Mrg::Grid::SerializedConfigs::ConfigLoader.new(self, snaptext).load
          
        end
        
        expose :LoadSnapshot do |args|
          args.declare :name, :sstr, :in, :desc=>"A name for the configuration to load."
        end
        
        def RemoveSnapshot(name)
          Snapshot.find_first_by_name(name).delete
        end
        
        expose :RemoveSnapshot do |args|
          args.declare :name, :sstr, :in, :desc=>"A name for the configuration to load."
        end

        # <method name="LoadSnapshot">
        #    <arg name="name" dir="I" type="sstr"/>
        # </method>
        # 
        # <method name="RemoveSnapshot">
        #    <arg name="name" dir="I" type="sstr"/>
        # </method>
        
        
        private
        def clear_db
          MAIN_DB_TABLES.each do |table|
            table.delete_all rescue table.find_all.each {|row| row.delete}
          end
        end
      end
    end
  end
end
