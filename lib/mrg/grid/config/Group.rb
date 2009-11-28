module Mrg
  module Grid
    module Config
      class Group
        include SPQR::Manageable
        
        spqr_package 'mrg.grid.config'
        spqr_class 'Group'
        # Find method (NB:  you must implement this)
        def Group.find_by_id(objid)
          Group.new
        end
        
# Find-all method (NB:  you must implement this)
        def Group.find_all
          [Group.new]
        end
        ### Property method declarations
        
        # property uid uint32 
        def uid
          log.debug 'Requested property uid'
          nil
        end
        
        def uid=(val)
          log.debug 'Set property uid to #{val}'
          nil
        end
        
        spqr_property :uid, :uint32, :index=>true
        ### Schema method declarations
        
        # ModifyMembership 
        # * command (sstr/I)
        # Valid commands are 'ADD', 'REMOVE', 'UNION', 'INTERSECT', 'DIFF', and 'REPLACE'.
        # * nodes (map/I)
        # A set of nodes
        # * options (map/I)
        # 
        def ModifyMembership(args)
          # Print values of in parameters
          log.debug "command => #{args["command"]}" # 
          log.debug "nodes => #{args["nodes"]}" # 
          log.debug "options => #{args["options"]}" # 
        end
        
        spqr_expose :ModifyMembership do |args|
          args.declare :command, :sstr, :in, {}
          args.declare :nodes, :map, :in, {}
          args.declare :options, :map, :in, {}
        end
        
        # GetMembership 
        # * list (map/O)
        # A set of the nodes associated with this group
        def GetMembership(args)
          # Assign values to out parameters
          args["list"] = args["list"]
        end
        
        spqr_expose :GetMembership do |args|
          args.declare :list, :map, :out, {}
        end
        
        # GetName 
        # * name (sstr/O)
        # 
        def GetName(args)
          # Assign values to out parameters
          args["name"] = args["name"]
        end
        
        spqr_expose :GetName do |args|
          args.declare :name, :sstr, :out, {}
        end
        
        # SetName 
        # * name (sstr/I)
        # 
        def SetName(args)
          # Print values of in parameters
          log.debug "name => #{args["name"]}" # 
        end
        
        spqr_expose :SetName do |args|
          args.declare :name, :sstr, :in, {}
        end
        
        # GetFeatures 
        # * features (map/O)
        # A list of features to be applied to this group, in priority order (that is, the first one will be applied last, to take effect after ones with less priority)
        def GetFeatures(args)
          # Assign values to out parameters
          args["features"] = args["features"]
        end
        
        spqr_expose :GetFeatures do |args|
          args.declare :features, :map, :out, {}
        end
        
        # ModifyFeaturePriorities 
        # * features (map/IO)
        # A list of features in this group (as returned by GetFeatures), in a new priority order. Features that are in this list but not in the group will be ignored. Features that are in the group but not in this list will be placed in arbitrary priority order after every feature in this list. After this method executes, features will contain the priority ordering of every feature assigned to this group.
        def ModifyFeaturePriorities(args)
          # Print values of in/out parameters
          log.debug "features => #{args["features"]}" # 
          # Assign values to in/out parameters
          args["features"] = args["features"]
        end
        
        spqr_expose :ModifyFeaturePriorities do |args|
          args.declare :features, :map, :inout, {}
        end
        
        # ModifyFeatureSet 
        # * command (sstr/I)
        # Valid commands are 'ADD', 'REMOVE', 'UNION', 'INTERSECT', 'DIFF', and 'REPLACE'.
        # * features (map/I)
        # A set of features to apply to dependency priority
        # * params (map/O)
        # A map(paramName, reasonString) for parameters that need to be set as a result of the features added before the configuration will be considered valid
        def ModifyFeatureSet(args)
          # Print values of in parameters
          log.debug "command => #{args["command"]}" # 
          log.debug "features => #{args["features"]}" # 
          # Assign values to out parameters
          args["params"] = args["params"]
        end
        
        spqr_expose :ModifyFeatureSet do |args|
          args.declare :params, :map, :out, {}
          args.declare :command, :sstr, :in, {}
          args.declare :features, :map, :in, {}
        end
        
        # GetParams 
        # * params (map/O)
        # A map(paramName, value) of parameters and their values that are specific to the group
        def GetParams(args)
          # Assign values to out parameters
          args["params"] = args["params"]
        end
        
        spqr_expose :GetParams do |args|
          args.declare :params, :map, :out, {}
        end
        
        # ModifyParams 
        # * command (sstr/I)
        # Valid commands are 'ADD', 'REMOVE', 'UNION', 'INTERSECT', 'DIFF', and 'REPLACE'.
        # * params (map/I)
        # A map(featureName, priority) of feature names and their dependency priority
        def ModifyParams(args)
          # Print values of in parameters
          log.debug "command => #{args["command"]}" # 
          log.debug "params => #{args["params"]}" # 
        end
        
        spqr_expose :ModifyParams do |args|
          args.declare :command, :sstr, :in, {}
          args.declare :params, :map, :in, {}
        end
      end
    end
  end
end
