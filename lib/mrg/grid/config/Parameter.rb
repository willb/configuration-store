require 'spqr/spqr'
require 'rhubarb/rhubarb'

module Mrg
  module Grid
    module Config
      class Parameter
        include ::Rhubarb::Persisting
        include ::SPQR::Manageable

        qmf_package_name 'mrg.grid.config'
        qmf_class_name 'Parameter'
        ### Property method declarations
        # property name sstr 

        declare_column :name, :string, :not_null
        declare_index_on :name
        
        declare_column :kind, :string, :default, :string
        declare_column :default_val, :string
        declare_column :must_change, :boolean, :default, :false
        declare_column :level, :integer
        declare_column :needsRestart, :boolean

        qmf_property :name, :sstr, :index=>true
        ### Schema method declarations
        
        # GetType 
        # * type (uint8/O)
        def GetType()
          # Assign values to output parameters
          return kind
        end
        
        expose :GetType do |args|
          args.declare :type, :uint8, :out, {}
        end
        
        # SetType 
        # * ty (uint8/I)
        def SetType(type)
          # Print values of input parameters
          log.debug "SetType: type => #{type}"
          self.kind = type
        end
        
        expose :SetType do |args|
          args.declare :type, :uint8, :in, {}
        end
        
        # GetValue 
        # * value (lstr/O)
        def GetValue()
          # Assign values to output parameters
          value ||= ""
          # Return value
          return value
        end
        
        expose :GetValue do |args|
          args.declare :value, :lstr, :out, {}
        end
        
        # SetValue 
        # * value (lstr/I)
        def SetValue(value)
          # Print values of input parameters
          log.debug "SetValue: value => #{value}"
        end
        
        expose :SetValue do |args|
          args.declare :value, :lstr, :in, {}
        end
        
        # GetDefault 
        # * default (lstr/O)
        def GetDefault()
          # Assign values to output parameters
          self.default_val ||= ""
          # Return value
          return self.default_val
        end
        
        expose :GetDefault do |args|
          args.declare :default, :lstr, :out, {}
        end
        
        # SetDefault 
        # * default (lstr/I)
        def SetDefault(default)
          # Print values of input parameters
          log.debug "SetDefault: default => #{default}"
          self.default_val = default
        end
        
        expose :SetDefault do |args|
          args.declare :default, :lstr, :in, {}
        end
        
        # GetDescription 
        # * description (lstr/O)
        def GetDescription()
          # Assign values to output parameters
          self.description ||= ""
          # Return value
          return self.description
        end
        
        expose :GetDescription do |args|
          args.declare :description, :lstr, :out, {}
        end
        
        # SetDescription 
        # * description (lstr/I)
        def SetDescription(description)
          # Print values of input parameters
          log.debug "SetDescription: description => #{description}"
          self.description = description
        end
        
        expose :SetDescription do |args|
          args.declare :description, :lstr, :in, {}
        end
        
        # GetDefaultMustChange 
        # * mustChange (bool/O)
        def GetDefaultMustChange()
          return self.must_change
        end
        
        expose :GetDefaultMustChange do |args|
          args.declare :mustChange, :bool, :out, {}
        end
        
        # SetDefaultMustChange 
        # * mustChange (bool/I)
        def SetDefaultMustChange(mustChange)
          # Print values of input parameters
          log.debug "SetDefaultMustChange: mustChange => #{mustChange}"
          self.must_change = mustChange
        end
        
        expose :SetDefaultMustChange do |args|
          args.declare :mustChange, :bool, :in, {}
        end
        
        # GetVisibilityLevel 
        # * level (uint8/O)
        def GetVisibilityLevel()
          self.level ||= 0
          # Return value
          return self.level
        end
        
        expose :GetVisibilityLevel do |args|
          args.declare :level, :uint8, :out, {}
        end
        
        # SetVisibilityLevel 
        # * level (uint8/I)
        def SetVisibilityLevel(level)
          # Print values of input parameters
          log.debug "SetVisibilityLevel: level => #{level}"
          self.level = level
        end
        
        expose :SetVisibilityLevel do |args|
          args.declare :level, :uint8, :in, {}
        end
        
        # GetRequiresRestart 
        # * needsRestart (bool/O)
        def GetRequiresRestart()
          # Assign values to output parameters
          self.needsRestart ||= false
          # Return value
          return self.needsRestart
        end
        
        expose :GetRequiresRestart do |args|
          args.declare :needsRestart, :bool, :out, {}
        end
        
        # SetRequiresRestart 
        # * needsRestart (bool/I)
        def SetRequiresRestart(needsRestart)
          # Print values of input parameters
          log.debug "SetRequiresRestart: needsRestart => #{needsRestart}"
          self.needsRestart = needsRestart
        end
        
        expose :SetRequiresRestart do |args|
          args.declare :needsRestart, :bool, :in, {}
        end
        
        # GetDepends 
        # * depends (map/O)
        #   A map(paramName, priority) of parameter names and their dependency priority
        def GetDepends()
          # Assign values to output parameters
          depends ||= {}
          # Return value
          return depends
        end
        
        expose :GetDepends do |args|
          args.declare :depends, :map, :out, {}
        end
        
        # ModifyDepends 
        # * command (sstr/I)
        #   Valid commands are 'ADD', 'REMOVE', 'UNION', 'INTERSECT', 'DIFF', and 'REPLACE'.
        # * depends (map/I)
        #   A map(paramName, priority) of parameter names and their dependency priority
        def ModifyDepends(command,depends)
          # Print values of input parameters
          log.debug "ModifyDepends: command => #{command}"
          log.debug "ModifyDepends: depends => #{depends}"
        end
        
        expose :ModifyDepends do |args|
          args.declare :command, :sstr, :in, {}
          args.declare :depends, :map, :in, {}
        end
        
        # GetConflicts 
        # * conflicts (map/O)
        #   A set of parameter names that conflict with the parameter
        def GetConflicts()
          # Assign values to output parameters
          conflicts ||= {}
          # Return value
          return conflicts
        end
        
        expose :GetConflicts do |args|
          args.declare :conflicts, :map, :out, {}
        end
        
        # ModifyConflicts 
        # * command (sstr/I)
        #   Valid commands are 'ADD', 'REMOVE', 'UNION', 'INTERSECT', 'DIFF', and 'REPLACE'.
        # * conflicts (map/I)
        #   A map(paramName, priority) of parameter names and their conflict priority
        def ModifyConflicts(command,conflicts)
          # Print values of input parameters
          log.debug "ModifyConflicts: command => #{command}"
          log.debug "ModifyConflicts: conflicts => #{conflicts}"
        end
        
        expose :ModifyConflicts do |args|
          args.declare :command, :sstr, :in, {}
          args.declare :conflicts, :map, :in, {}
        end
      end
    end
  end
end
