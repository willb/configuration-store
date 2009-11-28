module Mrg
  module Grid
    module Config
      class Parameter
        include SPQR::Manageable
        
        spqr_package 'mrg.grid.config'
        spqr_class 'Parameter'
        # Find method (NB:  you must implement this)
        def Parameter.find_by_id(objid)
          Parameter.new
        end
        
# Find-all method (NB:  you must implement this)
        def Parameter.find_all
          [Parameter.new]
        end
        ### Property method declarations
        
        # property name sstr 
        def name
          log.debug 'Requested property name'
          nil
        end
        
        def name=(val)
          log.debug 'Set property name to #{val}'
          nil
        end
        
        spqr_property :name, :sstr, :index=>true
        ### Schema method declarations
        
        # GetType 
        # * type (uint8/O)
        # 
        def GetType(args)
          # Assign values to out parameters
          args["type"] = args["type"]
        end
        
        spqr_expose :GetType do |args|
          args.declare :type, :uint8, :out, {}
        end
        
        # SetType 
        # * type (uint8/I)
        # 
        def SetType(args)
          # Print values of in parameters
          log.debug "type => #{args["type"]}" # 
        end
        
        spqr_expose :SetType do |args|
          args.declare :type, :uint8, :in, {}
        end
        
        # GetValue 
        # * value (lstr/O)
        # 
        def GetValue(args)
          # Assign values to out parameters
          args["value"] = args["value"]
        end
        
        spqr_expose :GetValue do |args|
          args.declare :value, :lstr, :out, {}
        end
        
        # SetValue 
        # * value (lstr/I)
        # 
        def SetValue(args)
          # Print values of in parameters
          log.debug "value => #{args["value"]}" # 
        end
        
        spqr_expose :SetValue do |args|
          args.declare :value, :lstr, :in, {}
        end
        
        # GetDefault 
        # * default (lstr/O)
        # 
        def GetDefault(args)
          # Assign values to out parameters
          args["default"] = args["default"]
        end
        
        spqr_expose :GetDefault do |args|
          args.declare :default, :lstr, :out, {}
        end
        
        # SetDefault 
        # * default (lstr/I)
        # 
        def SetDefault(args)
          # Print values of in parameters
          log.debug "default => #{args["default"]}" # 
        end
        
        spqr_expose :SetDefault do |args|
          args.declare :default, :lstr, :in, {}
        end
        
        # GetDescription 
        # * description (lstr/O)
        # 
        def GetDescription(args)
          # Assign values to out parameters
          args["description"] = args["description"]
        end
        
        spqr_expose :GetDescription do |args|
          args.declare :description, :lstr, :out, {}
        end
        
        # SetDescription 
        # * description (lstr/I)
        # 
        def SetDescription(args)
          # Print values of in parameters
          log.debug "description => #{args["description"]}" # 
        end
        
        spqr_expose :SetDescription do |args|
          args.declare :description, :lstr, :in, {}
        end
        
        # GetDefaultMustChange 
        # * mustChange (bool/O)
        # 
        def GetDefaultMustChange(args)
          # Assign values to out parameters
          args["mustChange"] = args["mustChange"]
        end
        
        spqr_expose :GetDefaultMustChange do |args|
          args.declare :mustChange, :bool, :out, {}
        end
        
        # SetDefaultMustChange 
        # * mustChange (bool/I)
        # 
        def SetDefaultMustChange(args)
          # Print values of in parameters
          log.debug "mustChange => #{args["mustChange"]}" # 
        end
        
        spqr_expose :SetDefaultMustChange do |args|
          args.declare :mustChange, :bool, :in, {}
        end
        
        # GetVisibilityLevel 
        # * level (uint8/O)
        # 
        def GetVisibilityLevel(args)
          # Assign values to out parameters
          args["level"] = args["level"]
        end
        
        spqr_expose :GetVisibilityLevel do |args|
          args.declare :level, :uint8, :out, {}
        end
        
        # SetVisibilityLevel 
        # * level (uint8/I)
        # 
        def SetVisibilityLevel(args)
          # Print values of in parameters
          log.debug "level => #{args["level"]}" # 
        end
        
        spqr_expose :SetVisibilityLevel do |args|
          args.declare :level, :uint8, :in, {}
        end
        
        # GetRequiresRestart 
        # * needsRestart (bool/O)
        # 
        def GetRequiresRestart(args)
          # Assign values to out parameters
          args["needsRestart"] = args["needsRestart"]
        end
        
        spqr_expose :GetRequiresRestart do |args|
          args.declare :needsRestart, :bool, :out, {}
        end
        
        # SetRequiresRestart 
        # * needsRestart (bool/I)
        # 
        def SetRequiresRestart(args)
          # Print values of in parameters
          log.debug "needsRestart => #{args["needsRestart"]}" # 
        end
        
        spqr_expose :SetRequiresRestart do |args|
          args.declare :needsRestart, :bool, :in, {}
        end
        
        # GetDepends 
        # * depends (map/O)
        # A map(paramName, priority) of parameter names and their dependency priority
        def GetDepends(args)
          # Assign values to out parameters
          args["depends"] = args["depends"]
        end
        
        spqr_expose :GetDepends do |args|
          args.declare :depends, :map, :out, {}
        end
        
        # ModifyDepends 
        # * command (sstr/I)
        # Valid commands are 'ADD', 'REMOVE', 'UNION', 'INTERSECT', 'DIFF', and 'REPLACE'.
        # * depends (map/I)
        # A map(paramName, priority) of parameter names and their dependency priority
        def ModifyDepends(args)
          # Print values of in parameters
          log.debug "command => #{args["command"]}" # 
          log.debug "depends => #{args["depends"]}" # 
        end
        
        spqr_expose :ModifyDepends do |args|
          args.declare :command, :sstr, :in, {}
          args.declare :depends, :map, :in, {}
        end
        
        # GetConflicts 
        # * conflicts (map/O)
        # A set of parameter names that conflict with the parameter
        def GetConflicts(args)
          # Assign values to out parameters
          args["conflicts"] = args["conflicts"]
        end
        
        spqr_expose :GetConflicts do |args|
          args.declare :conflicts, :map, :out, {}
        end
        
        # ModifyConflicts 
        # * command (sstr/I)
        # Valid commands are 'ADD', 'REMOVE', 'UNION', 'INTERSECT', 'DIFF', and 'REPLACE'.
        # * conflicts (map/I)
        # A map(paramName, priority) of parameter names and their conflict priority
        def ModifyConflicts(args)
          # Print values of in parameters
          log.debug "command => #{args["command"]}" # 
          log.debug "conflicts => #{args["conflicts"]}" # 
        end
        
        spqr_expose :ModifyConflicts do |args|
          args.declare :command, :sstr, :in, {}
          args.declare :conflicts, :map, :in, {}
        end
      end
    end
  end
end
