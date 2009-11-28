require 'spqr/spqr'

module Mrg
  module Grid
    module Config
      class Store
        include ::SPQR::Manageable
        
        spqr_package 'mrg.grid.config'
        spqr_class 'Store'
        # Find method (NB:  you must implement this)
        def Store.find_by_id(objid)
          Store.new
        end
        
# Find-all method (NB:  you must implement this)
        def Store.find_all
          [Store.new]
        end
        ### Property method declarations
        
        # property APIVersionNumber uint32 The version of the API the store supports
        def APIVersionNumber
          log.debug 'Requested property APIVersionNumber'
          nil
        end
        
        def APIVersionNumber=(val)
          log.debug 'Set property APIVersionNumber to #{val}'
          nil
        end
        
        spqr_property :APIVersionNumber, :uint32, :desc=>"The version of the API the store supports", :index=>false
        ### Schema method declarations
        
        # GetGroup 
        # * query (map/I)
        # A map(queryType, value) that defines the group desired. The queryType can be either 'ID' or 'Name'. 'ID' queryTypes will search for a group with the ID defined in value. 'Name' queryTypes will search for a group with the name defined in value.
        # * obj (objId/O)
        # 
        def GetGroup(args)
          # Print values of in parameters
          log.debug "query => #{args["query"]}" # 
          # Assign values to out parameters
          args["obj"] = args["obj"]
        end
        
        spqr_expose :GetGroup do |args|
          args.declare :obj, :objId, :out, {}
          args.declare :query, :map, :in, {}
        end
        
        # AddExplicitGroup 
        # * name (sstr/I)
        # 
        # * obj (objId/O)
        # 
        def AddExplicitGroup(args)
          # Print values of in parameters
          log.debug "name => #{args["name"]}" # 
          # Assign values to out parameters
          args["obj"] = args["obj"]
        end
        
        spqr_expose :AddExplicitGroup do |args|
          args.declare :obj, :objId, :out, {}
          args.declare :name, :sstr, :in, {}
        end
        
        # RemoveGroup 
        # * uid (uint32/I)
        # 
        def RemoveGroup(args)
          # Print values of in parameters
          log.debug "uid => #{args["uid"]}" # 
        end
        
        spqr_expose :RemoveGroup do |args|
          args.declare :uid, :uint32, :in, {}
        end
        
        # GetFeature 
        # * name (sstr/I)
        # 
        # * obj (objId/O)
        # 
        def GetFeature(args)
          # Print values of in parameters
          log.debug "name => #{args["name"]}" # 
          # Assign values to out parameters
          args["obj"] = args["obj"]
        end
        
        spqr_expose :GetFeature do |args|
          args.declare :obj, :objId, :out, {}
          args.declare :name, :sstr, :in, {}
        end
        
        # AddFeature 
        # * name (sstr/I)
        # 
        # * obj (objId/O)
        # 
        def AddFeature(args)
          # Print values of in parameters
          log.debug "name => #{args["name"]}" # 
          # Assign values to out parameters
          args["obj"] = args["obj"]
        end
        
        spqr_expose :AddFeature do |args|
          args.declare :obj, :objId, :out, {}
          args.declare :name, :sstr, :in, {}
        end
        
        # RemoveFeature 
        # * uid (uint32/I)
        # 
        def RemoveFeature(args)
          # Print values of in parameters
          log.debug "uid => #{args["uid"]}" # 
        end
        
        spqr_expose :RemoveFeature do |args|
          args.declare :uid, :uint32, :in, {}
        end
        
        # GetConfiguration 
        # * Query (map/I)
        # A query that defines the configuration desired. Valid values for the key are 'ID' or 'Name'. 'ID' keys should contain a specific ConfigurationId as its value, whereas 'Name' keys should contain a Configuration Name as its value
        # * obj (objId/O)
        # 
        def GetConfiguration(args)
          # Print values of in parameters
          log.debug "Query => #{args["Query"]}" # 
          # Assign values to out parameters
          args["obj"] = args["obj"]
        end
        
        spqr_expose :GetConfiguration do |args|
          args.declare :obj, :objId, :out, {}
          args.declare :Query, :map, :in, {}
        end
        
        # MakeSnapshot 
        # * name (sstr/I)
        # A name for this configuration. A blank name will result in the store creating a name
        # * uid (uint32/O)
        # 
        # * params (map/O)
        # A map (param:reasonString) containing a list of parameters and a reasonString for the parameter that must be set for the configuration to be valid
        def MakeSnapshot(args)
          # Print values of in parameters
          log.debug "name => #{args["name"]}" # 
          # Assign values to out parameters
          args["uid"] = args["uid"]
          args["params"] = args["params"]
        end
        
        spqr_expose :MakeSnapshot do |args|
          args.declare :uid, :uint32, :out, {}
          args.declare :params, :map, :out, {}
          args.declare :name, :sstr, :in, {}
        end
        
        # ChangeConfiguration 
        # * uid (uint32/I)
        # 
        def ChangeConfiguration(args)
          # Print values of in parameters
          log.debug "uid => #{args["uid"]}" # 
        end
        
        spqr_expose :ChangeConfiguration do |args|
          args.declare :uid, :uint32, :in, {}
        end
        
        # ActivateConfiguration 
        # * params (map/O)
        # A map (param:reasonString) containing a list of parameters and a reasonString for the parameter that must be set for the configuration to be valid
        def ActivateConfiguration(args)
          # Assign values to out parameters
          args["params"] = args["params"]
        end
        
        spqr_expose :ActivateConfiguration do |args|
          args.declare :params, :map, :out, {}
        end
        
        # AddNode 
        # * name (sstr/I)
        # 
        # * obj (objId/O)
        # 
        def AddNode(args)
          # Print values of in parameters
          log.debug "name => #{args["name"]}" # 
          # Assign values to out parameters
          args["obj"] = args["obj"]
        end
        
        spqr_expose :AddNode do |args|
          args.declare :obj, :objId, :out, {}
          args.declare :name, :sstr, :in, {}
        end
        
        # RemoveNode 
        # * name (sstr/I)
        # 
        def RemoveNode(args)
          # Print values of in parameters
          log.debug "name => #{args["name"]}" # 
        end
        
        spqr_expose :RemoveNode do |args|
          args.declare :name, :sstr, :in, {}
        end
        
        # GetParam 
        # * name (sstr/I)
        # 
        # * obj (objId/O)
        # A reference to the parameter object that matches the name supplied
        def GetParam(args)
          # Print values of in parameters
          log.debug "name => #{args["name"]}" # 
          # Assign values to out parameters
          args["obj"] = args["obj"]
        end
        
        spqr_expose :GetParam do |args|
          args.declare :obj, :objId, :out, {}
          args.declare :name, :sstr, :in, {}
        end
        
        # AddParam 
        # * name (sstr/I)
        # 
        # * obj (objId/O)
        # A reference to the newly added parameter object
        def AddParam(args)
          # Print values of in parameters
          log.debug "name => #{args["name"]}" # 
          # Assign values to out parameters
          args["obj"] = args["obj"]
        end
        
        spqr_expose :AddParam do |args|
          args.declare :obj, :objId, :out, {}
          args.declare :name, :sstr, :in, {}
        end
        
        # RemoveParam 
        # * name (sstr/I)
        # 
        def RemoveParam(args)
          # Print values of in parameters
          log.debug "name => #{args["name"]}" # 
        end
        
        spqr_expose :RemoveParam do |args|
          args.declare :name, :sstr, :in, {}
        end
      end
    end
  end
end
