module Mrg
  module Grid
    module Config
      class Feature
        include SPQR::Manageable
        
        spqr_package 'mrg.grid.config'
        spqr_class 'Feature'
        # Find method (NB:  you must implement this)
        def Feature.find_by_id(objid)
          Feature.new
        end
        
# Find-all method (NB:  you must implement this)
        def Feature.find_all
          [Feature.new]
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
        # * list (map/O)
        # list of other features a feature includes
        def GetFeatures(args)
          # Assign values to out parameters
          args["list"] = args["list"]
        end
        
        spqr_expose :GetFeatures do |args|
          args.declare :list, :map, :out, {}
        end
        
        # ModifyFeatures 
        # * command (sstr/I)
        # Valid commands are 'ADD', 'REMOVE', 'UNION', 'INTERSECT', 'DIFF', and 'REPLACE'.
        # * features (map/I)
        # A list of other features a feature includes
        def ModifyFeatures(args)
          # Print values of in parameters
          log.debug "command => #{args["command"]}" # 
          log.debug "features => #{args["features"]}" # 
        end
        
        spqr_expose :ModifyFeatures do |args|
          args.declare :command, :sstr, :in, {}
          args.declare :features, :map, :in, {}
        end
        
        # GetParams 
        # * list (map/O)
        # A map(paramName, value) of parameters and their corresponding values that is specific to a group
        def GetParams(args)
          # Assign values to out parameters
          args["list"] = args["list"]
        end
        
        spqr_expose :GetParams do |args|
          args.declare :list, :map, :out, {}
        end
        
        # ModifyParams 
        # * command (sstr/I)
        # Valid commands are 'ADD', 'REMOVE', 'UNION', 'INTERSECT', 'DIFF', and 'REPLACE'.
        # * params (map/I)
        # A map(paramName, value) of parameters and their corresponding values that is specific to a group
        def ModifyParams(args)
          # Print values of in parameters
          log.debug "command => #{args["command"]}" # 
          log.debug "params => #{args["params"]}" # 
        end
        
        spqr_expose :ModifyParams do |args|
          args.declare :command, :sstr, :in, {}
          args.declare :params, :map, :in, {}
        end
        
        # GetConflicts 
        # * list (map/O)
        # A map(featureName, True) of other features a feature conflicts with for proper operation
        def GetConflicts(args)
          # Assign values to out parameters
          args["list"] = args["list"]
        end
        
        spqr_expose :GetConflicts do |args|
          args.declare :list, :map, :out, {}
        end
        
        # ModifyConflicts 
        # * command (sstr/I)
        # Valid commands are 'ADD', 'REMOVE', 'UNION', 'INTERSECT', 'DIFF', and 'REPLACE'.
        # * conflicts (map/I)
        # A set of other feature names that conflict with the feature
        def ModifyConflicts(args)
          # Print values of in parameters
          log.debug "command => #{args["command"]}" # 
          log.debug "conflicts => #{args["conflicts"]}" # 
        end
        
        spqr_expose :ModifyConflicts do |args|
          args.declare :command, :sstr, :in, {}
          args.declare :conflicts, :map, :in, {}
        end
        
        # GetDepends 
        # * list (map/O)
        # A list of other features that this feature depends on for proper operation, in priority order.
        def GetDepends(args)
          # Assign values to out parameters
          args["list"] = args["list"]
        end
        
        spqr_expose :GetDepends do |args|
          args.declare :list, :map, :out, {}
        end
        
        # ModifyDepends 
        # * command (sstr/I)
        # Valid commands are 'ADD', 'REMOVE', 'UNION', 'INTERSECT', 'DIFF', and 'REPLACE'.
        # * depends (map/I)
        # A set of other features a feature depends on. 
        def ModifyDepends(args)
          # Print values of in parameters
          log.debug "command => #{args["command"]}" # 
          log.debug "depends => #{args["depends"]}" # 
        end
        
        spqr_expose :ModifyDepends do |args|
          args.declare :command, :sstr, :in, {}
          args.declare :depends, :map, :in, {}
        end
        
        # GetSubsys 
        # * list (map/O)
        # A set of subsystem names that collaborate with the feature. This is used to determine subsystems that may need to be restarted if a configuration is changed
        def GetSubsys(args)
          # Assign values to out parameters
          args["list"] = args["list"]
        end
        
        spqr_expose :GetSubsys do |args|
          args.declare :list, :map, :out, {}
        end
        
        # ModifySubsys 
        # * command (sstr/I)
        # Valid commands are 'ADD', 'REMOVE', 'UNION', 'INTERSECT', 'DIFF', and 'REPLACE'.
        # * subsys (map/I)
        # A set of subsystem names that collaborate with the feature. This is used to determine subsystems that may need to be restarted if a configuration is changed
        def ModifySubsys(args)
          # Print values of in parameters
          log.debug "command => #{args["command"]}" # 
          log.debug "subsys => #{args["subsys"]}" # 
        end
        
        spqr_expose :ModifySubsys do |args|
          args.declare :command, :sstr, :in, {}
          args.declare :subsys, :map, :in, {}
        end
      end
    end
  end
end
