require 'spqr/spqr'
require 'rhubarb/rhubarb'
require 'mrg/grid/config/Subsystem'
require 'mrg/grid/config/ArcLabel'
require 'mrg/grid/config/ArcUtils'

require 'set'

module Mrg
  module Grid
    module Config
      class Feature
        include ::Rhubarb::Persisting
        include ::SPQR::Manageable

        qmf_package_name 'mrg.grid.config'
        qmf_class_name 'Feature'
        ### Property method declarations
        # property uid uint32 

        declare_column :name, :string
        declare_index_on :name
        
        def uid
          @row_id
        end
        
        def Feature.find_by_uid(u)
          find(u)
        end
        
        qmf_property :uid, :uint32, :index=>true
        ### Schema method declarations
        
        # GetName 
        # * name (sstr/O)
        def GetName()
          # Assign values to output parameters
          name ||= ""
          # Return value
          return name
        end
        
        expose :GetName do |args|
          args.declare :name, :sstr, :out, {}
        end
        
        # SetName 
        # * name (sstr/I)
        def SetName(name)
          # Print values of input parameters
          log.debug "SetName: name => #{name}"
        end
        
        expose :SetName do |args|
          args.declare :name, :sstr, :in, {}
        end
        
        # GetFeatures 
        # * list (map/O)
        #   list of other features a feature includes
        def GetFeatures()
          # Assign values to output parameters
          list ||= {}
          # Return value
          return list
        end
        
        expose :GetFeatures do |args|
          args.declare :list, :map, :out, {}
        end
        
        # ModifyFeatures 
        # * command (sstr/I)
        #   Valid commands are 'ADD', 'REMOVE', 'UNION', 'INTERSECT', 'DIFF', and 'REPLACE'.
        # * features (map/I)
        #   A list of other features a feature includes
        def ModifyFeatures(command,features)
          # Print values of input parameters
          log.debug "ModifyFeatures: command => #{command}"
          log.debug "ModifyFeatures: features => #{features}"
        end
        
        expose :ModifyFeatures do |args|
          args.declare :command, :sstr, :in, {}
          args.declare :features, :map, :in, {}
        end
        
        # GetParams 
        # * list (map/O)
        #   A map(paramName, value) of parameters and their corresponding values that is specific to a group
        def GetParams()
          # Assign values to output parameters
          list ||= {}
          # Return value
          return list
        end
        
        expose :GetParams do |args|
          args.declare :list, :map, :out, {}
        end
        
        # ModifyParams 
        # * command (sstr/I)
        #   Valid commands are 'ADD', 'REMOVE', 'UNION', 'INTERSECT', 'DIFF', and 'REPLACE'.
        # * params (map/I)
        #   A map(paramName, value) of parameters and their corresponding values that is specific to a group
        def ModifyParams(command,params)
          # Print values of input parameters
          log.debug "ModifyParams: command => #{command}"
          log.debug "ModifyParams: params => #{params}"
        end
        
        expose :ModifyParams do |args|
          args.declare :command, :sstr, :in, {}
          args.declare :params, :map, :in, {}
        end
        
        # GetConflicts 
        # * list (map/O)
        #   A map(featureName, True) of other features a feature conflicts with for proper operation
        def GetConflicts()
          # Assign values to output parameters
          list ||= {}
          # Return value
          return list
        end
        
        expose :GetConflicts do |args|
          args.declare :list, :map, :out, {}
        end
        
        # ModifyConflicts 
        # * command (sstr/I)
        #   Valid commands are 'ADD', 'REMOVE', 'UNION', 'INTERSECT', 'DIFF', and 'REPLACE'.
        # * conflicts (map/I)
        #   A set of other feature names that conflict with the feature
        def ModifyConflicts(command,conflicts)
          # Print values of input parameters
          log.debug "ModifyConflicts: command => #{command}"
          log.debug "ModifyConflicts: conflicts => #{conflicts}"
        end
        
        expose :ModifyConflicts do |args|
          args.declare :command, :sstr, :in, {}
          args.declare :conflicts, :map, :in, {}
        end
        
        # GetDepends 
        # * list (map/O)
        #   A list of other features that this feature depends on for proper operation, in priority order.
        def GetDepends()
          # Assign values to output parameters
          list ||= {}
          # Return value
          return list
        end
        
        expose :GetDepends do |args|
          args.declare :list, :map, :out, {}
        end
        
        # ModifyDepends 
        # * command (sstr/I)
        #   Valid commands are 'ADD', 'REMOVE', 'UNION', 'INTERSECT', 'DIFF', and 'REPLACE'.
        # * depends (map/I)
        #   A set of other features a feature depends on. 
        def ModifyDepends(command,depends)
          # Print values of input parameters
          log.debug "ModifyDepends: command => #{command}"
          log.debug "ModifyDepends: depends => #{depends}"
        end
        
        expose :ModifyDepends do |args|
          args.declare :command, :sstr, :in, {}
          args.declare :depends, :map, :in, {}
        end
        
        # GetSubsys 
        # * list (map/O)
        #   A set of subsystem names that collaborate with the feature. This is used to determine subsystems that may need to be restarted if a configuration is changed
        def GetSubsys()
          # Assign values to output parameters
          list ||= {}
          # Return value
          return list
        end
        
        expose :GetSubsys do |args|
          args.declare :list, :map, :out, {}
        end
        
        # ModifySubsys 
        # * command (sstr/I)
        #   Valid commands are 'ADD', 'REMOVE', 'UNION', 'INTERSECT', 'DIFF', and 'REPLACE'.
        # * subsys (map/I)
        #   A set of subsystem names that collaborate with the feature. This is used to determine subsystems that may need to be restarted if a configuration is changed
        def ModifySubsys(command,subsys)
          # Print values of input parameters
          log.debug "ModifySubsys: command => #{command}"
          log.debug "ModifySubsys: subsys => #{subsys}"
        end
        
        expose :ModifySubsys do |args|
          args.declare :command, :sstr, :in, {}
          args.declare :subsys, :map, :in, {}
        end
        
        private
        
      end
      
      class FeatureArc
        include ::Rhubarb::Persisting
        declare_column :source, :integer, :not_null, references(Feature, :on_delete=>:cascade)
        declare_column :dest, :integer, :not_null, references(Feature, :on_delete=>:cascade)
        declare_column :label, :integer, :not_null, references(ArcLabel)
      end
      
      class FeatureSubsys
        include ::Rhubarb::Persisting
        declare_column :source, :integer, :not_null, references(Feature, :on_delete=>:cascade)
        declare_column :dest, :integer, :not_null, references(Subsystem, :on_delete=>:cascade)
        declare_column :label, :integer, :not_null, references(ArcLabel)        
      end
    end
  end
end
