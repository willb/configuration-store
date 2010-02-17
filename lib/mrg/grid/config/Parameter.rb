require 'spqr/spqr'
require 'rhubarb/rhubarb'
require 'mrg/grid/config/ArcLabel'
require 'mrg/grid/config/ArcUtils'

require 'set'

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
        declare_column :description, :string
        declare_column :must_change, :boolean, :default, :false
        declare_column :level, :integer
        declare_column :needsRestart, :boolean

        qmf_property :name, :sstr, :index=>true
        ### Schema method declarations
        
        # GetType 
        # * type (uint8/O)
        def GetType()
          log.debug "GetType called on param #{self.inspect}"
          # Assign values to output parameters
          return kind
        end
        
        expose :GetType do |args|
          args.declare :type, :sstr, :out, {}
        end
        
        # SetType 
        # * ty (uint8/I)
        def SetType(type)
          # Print values of input parameters
          log.debug "SetType: type => #{type.inspect}"
          self.kind = type
        end
        
        expose :SetType do |args|
          args.declare :type, :sstr, :in, {}
        end
        
        # GetDefault 
        # * default (lstr/O)
        def GetDefault()
          log.debug "GetDefault called on param #{self.inspect}"
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
          log.debug "SetDefault: default => #{default.inspect}"
          DirtyElement.dirty_parameter(self)
          self.default_val = default
        end
        
        expose :SetDefault do |args|
          args.declare :default, :lstr, :in, {}
        end
        
        # GetDescription 
        # * description (lstr/O)
        def GetDescription()
          log.debug "GetDescription called on param #{self.inspect}"
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
          log.debug "SetDescription: description => #{description.inspect}"
          # XXX:  is this necessary?
          # DirtyElement.dirty_parameter(self)
          self.description = description
        end
        
        expose :SetDescription do |args|
          args.declare :description, :lstr, :in, {}
        end
        
        # GetDefaultMustChange 
        # * mustChange (bool/O)
        def GetDefaultMustChange()
          log.debug "GetDefaultMustChange called on param #{self.inspect}"
          return self.must_change
        end
        
        expose :GetDefaultMustChange do |args|
          args.declare :mustChange, :bool, :out, {}
        end
        
        # SetDefaultMustChange 
        # * mustChange (bool/I)
        def SetDefaultMustChange(mustChange)
          # Print values of input parameters
          log.debug "SetDefaultMustChange: mustChange => #{mustChange.inspect}"
          DirtyElement.dirty_parameter(self)
          self.must_change = mustChange
        end
        
        expose :SetDefaultMustChange do |args|
          args.declare :mustChange, :bool, :in, {}
        end
        
        # GetVisibilityLevel 
        # * level (uint8/O)
        def GetVisibilityLevel()
          log.debug "GetVisibilityLevel called on param #{self.inspect}"
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
          log.debug "SetVisibilityLevel: level => #{level.inspect}"
          # XXX:  Is this necessary?
          # DirtyElement.dirty_parameter(self)
          self.level = level
        end
        
        expose :SetVisibilityLevel do |args|
          args.declare :level, :uint8, :in, {}
        end
        
        # GetRequiresRestart 
        # * needsRestart (bool/O)
        def GetRequiresRestart()
          log.debug "GetRequiresRestart called on param #{self.inspect}"
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
          log.debug "SetRequiresRestart: needsRestart => #{needsRestart.inspect}"
          DirtyElement.dirty_parameter(self)
          self.needsRestart = needsRestart
        end
        
        expose :SetRequiresRestart do |args|
          args.declare :needsRestart, :bool, :in, {}
        end
        
        # GetDepends 
        # * depends (map/O)
        #   A set of parameter names that this one depends on
        def GetDepends()
          log.debug "GetDepends called on param #{self.inspect}"
          return FakeSet[*depends]
        end
        
        expose :GetDepends do |args|
          args.declare :depends, :map, :out, {}
        end
        
        # ModifyDepends 
        # * command (sstr/I)
        #   Valid commands are 'ADD', 'REMOVE', 'UNION', 'INTERSECT', 'DIFF', and 'REPLACE'.
        # * depends (map/I)
        #   A set of parameter names that this one depends on
        def ModifyDepends(command,deps,options)
          deps ||= {}
          # Print values of input parameters
          log.debug "ModifyDepends: command => #{command.inspect}"
          log.debug "ModifyDepends: depends => #{deps.inspect}"
          modify_arcs(command,deps,options,:depends,:depends=,:explain=>"depend upon")
          DirtyElement.dirty_parameter(self)
        end
        
        expose :ModifyDepends do |args|
          args.declare :command, :sstr, :in, {}
          args.declare :depends, :map, :in, {}
          args.declare :options, :map, :in, {}
        end
        
        # GetConflicts 
        # * conflicts (map/O)
        #   A set of parameter names that conflict with the parameter
        def GetConflicts()
          log.debug "GetConflicts called on param #{self.inspect}"
          return FakeSet[*conflicts]
        end
        
        expose :GetConflicts do |args|
          args.declare :conflicts, :map, :out, {}
        end
        
        # ModifyConflicts 
        # * command (sstr/I)
        #   Valid commands are 'ADD', 'REMOVE', 'UNION', 'INTERSECT', 'DIFF', and 'REPLACE'.
        # * conflicts (map/I)
        #   A set of parameter names that conflict with this one
        def ModifyConflicts(command,conflicts,options)
          conflicts ||= {}
          # Print values of input parameters
          log.debug "ModifyConflicts: command => #{command.inspect}"
          log.debug "ModifyConflicts: conflicts => #{conflicts.inspect}"
          modify_arcs(command,conflicts,options,:conflicts,:conflicts=,:explain=>"conflict with")
          DirtyElement.dirty_parameter(self)
        end
        
        expose :ModifyConflicts do |args|
          args.declare :command, :sstr, :in, {}
          args.declare :conflicts, :map, :in, {}
          args.declare :options, :map, :in, {}
        end
        
        def Parameter.s_that_must_change
          self.find_by(:must_change=>true).inject({}) do |acc, param|
            acc[param.name] = param.default_val
            acc
          end
        end
        
        private
        
        include ArcUtils
        
        def depends
          find_arcs(ParameterArc,ArcLabel.depends_on('param')) {|pa| pa.dest.name }
        end
        
        def conflicts
          find_arcs(ParameterArc,ArcLabel.conflicts_with('param')) {|pa| pa.dest.name }
        end
        
        def depends=(deps)
          set_arcs(ParameterArc, ArcLabel.depends_on('param'), deps, :find_first_by_name)
        end
        
        def conflicts=(conflicts)
          set_arcs(ParameterArc, ArcLabel.conflicts_with('param'), conflicts, :find_first_by_name)
        end
      end
    
      class ParameterArc
        include ::Rhubarb::Persisting
        declare_column :source, :integer, :not_null, references(Parameter, :on_delete=>:cascade)
        declare_column :dest, :integer, :not_null, references(Parameter, :on_delete=>:cascade)
        declare_column :label, :integer, :not_null, references(ArcLabel)
      end
    end
  end
end
