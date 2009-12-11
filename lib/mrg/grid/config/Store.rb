require 'spqr/spqr'

module Mrg
  module Grid
    module Config
      class Store
        include ::SPQR::Manageable

        qmf_package_name 'mrg.grid.config'
        qmf_class_name 'Store'

        ### Property method declarations
        # property APIVersionNumber uint32 The version of the API the store supports
        attr_accessor :apiVersionNumber
        qmf_property :apiVersionNumber, :uint32, :desc=>"The version of the API the store supports", :index=>false
        ### Schema method declarations
        
        # GetGroup 
        # * query (map/I)
        #   A map(queryType, value) that defines the group desired. The queryType can be either 'ID' or 'Name'. 'ID' queryTypes will search for a group with the ID defined in value. 'Name' queryTypes will search for a group with the name defined in value.
        # * obj (objId/O)
        def GetGroup(query)
          # Print values of input parameters
          log.debug "GetGroup: query => #{query}"
          # Assign values to output parameters
          obj ||= nil
          # Return value
          return obj
        end
        
        expose :GetGroup do |args|
          args.declare :obj, :objId, :out, {}
          args.declare :query, :map, :in, {}
        end
        
        # AddExplicitGroup 
        # * name (sstr/I)
        # * obj (objId/O)
        def AddExplicitGroup(name)
          # Print values of input parameters
          log.debug "AddExplicitGroup: name => #{name}"
          # Assign values to output parameters
          obj ||= nil
          # Return value
          return obj
        end
        
        expose :AddExplicitGroup do |args|
          args.declare :obj, :objId, :out, {}
          args.declare :name, :sstr, :in, {}
        end
        
        # RemoveGroup 
        # * uid (uint32/I)
        def RemoveGroup(uid)
          # Print values of input parameters
          log.debug "RemoveGroup: uid => #{uid}"
        end
        
        expose :RemoveGroup do |args|
          args.declare :uid, :uint32, :in, {}
        end
        
        # GetFeature 
        # * name (sstr/I)
        # * obj (objId/O)
        def GetFeature(name)
          # Print values of input parameters
          log.debug "GetFeature: name => #{name}"
          # Assign values to output parameters
          obj ||= nil
          # Return value
          return obj
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
          log.debug "AddFeature: name => #{name}"
          # Assign values to output parameters
          obj ||= nil
          # Return value
          return obj
        end
        
        expose :AddFeature do |args|
          args.declare :obj, :objId, :out, {}
          args.declare :name, :sstr, :in, {}
        end
        
        # RemoveFeature 
        # * uid (uint32/I)
        def RemoveFeature(uid)
          # Print values of input parameters
          log.debug "RemoveFeature: uid => #{uid}"
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
          log.debug "GetConfiguration: query => #{query}"
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
          log.debug "MakeSnapshot: name => #{name}"
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
          log.debug "ChangeConfiguration: uid => #{uid}"
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
          log.debug "AddNode: name => #{name}"

          # Return a newly-created node
          return Node.create(:name => name)
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
          log.debug "GetNode: name => #{name}"

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
          log.debug "RemoveNode: name => #{name}"

          # Actually remove the node
          Node.find_first_by_name(name).remove
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
          log.debug "GetParam: name => #{name}"
          # Assign values to output parameters
          obj ||= nil
          # Return value
          return obj
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
          log.debug "AddParam: name => #{name}"
          # Return value
          return Parameter.create(:name => name)
        end
        
        expose :AddParam do |args|
          args.declare :obj, :objId, :out, {}
          args.declare :name, :sstr, :in, {}
        end
        
        # RemoveParam 
        # * name (sstr/I)
        def RemoveParam(name)
          # Print values of input parameters
          log.debug "RemoveParam: name => #{name}"
        end
        
        expose :RemoveParam do |args|
          args.declare :name, :sstr, :in, {}
        end
      end
    end
  end
end
