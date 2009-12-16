require 'spqr/spqr'
require 'rhubarb/rhubarb'
require 'mrg/grid/config/Subsystem'
require 'mrg/grid/config/Parameter'
require 'mrg/grid/config/ArcLabel'
require 'mrg/grid/config/ArcUtils'
require 'mrg/grid/config/QmfUtils'

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
          return self.name
        end
        
        expose :GetName do |args|
          args.declare :name, :sstr, :out, {}
        end
        
        # SetName 
        # * name (sstr/I)
        def SetName(name)
          # Print values of input parameters
          log.debug "SetName: name => #{name}"
          raise "Feature name #{name} is taken" if (self.name != name and Feature.find_first_by_name(name))
          self.name = name
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
        #   Valid commands are 'ADD', 'REMOVE', and 'REPLACE'.
        # * features (map/I)
        #   A list of other features a feature includes
        def ModifyFeatures(command,features,options={})
          # Print values of input parameters
          log.debug "ModifyFeatures: command => #{command}"
          log.debug "ModifyFeatures: features => #{features}"
        end
        
        expose :ModifyFeatures do |args|
          args.declare :command, :sstr, :in, {}
          args.declare :features, :map, :in, {}
          args.declare :options, :map, :in, {}
        end
        
        # GetParams 
        # * list (map/O)
        #   A map(paramName, value) of parameters and their corresponding values that is specific to a group
        def GetParams()
          Hash[*FeatureParams.find_by(:feature=>self).map {|fp| [fp.param.name, fp.value]}.flatten]
        end
        
        expose :GetParams do |args|
          args.declare :list, :map, :out, {}
        end
        
        # ModifyParams 
        # * command (sstr/I)
        #   Valid commands are 'ADD', 'REMOVE', and 'REPLACE'.
        # * params (map/I)
        #   A map(paramName, value) of parameters and their corresponding values that is specific to a group
        def ModifyParams(command,pvmap,options={})
          # Print values of input parameters
          log.debug "ModifyParams: command => #{command}"
          log.debug "ModifyParams: params => #{pvmap}"
          
          pvmap ||= {}
          
          params = pvmap.keys.map do |pn|
            prow = Parameter.find_first_by_name(pn)
            raise "invalid parameter #{pn}" unless prow
            prow
          end
          
          case command
          when "ADD", "REMOVE" then
            params.each do |prow|
              pn = prow.name

              # Delete any prior mappings for each supplied param in either case
              FeatureParams.find_by(:feature=>self, :param=>prow).map {|fp| fp.delete}
              
              # Add new mappings when requested
              FeatureParams.create(:feature=>self, :param=>prow, :value=>pvmap[pn]) if command == "ADD"
            end
          when "REPLACE"
            FeatureParams.find_by(:feature=>self).map {|fp| fp.delete}

            params.each do |prow|
              pn = prow.name

              FeatureParams.create(:feature=>self, :param=>prow, :value=>pvmap[pn])
            end
          end
        end
        
        expose :ModifyParams do |args|
          args.declare :command, :sstr, :in, {}
          args.declare :params, :map, :in, {}
          args.declare :options, :map, :in, {}
        end
        
        # GetConflicts 
        # * list (map/O)
        #   A map(featureName, True) of other features a feature conflicts with for proper operation
        def GetConflicts()
          return FakeSet[*conflicts]
        end
        
        expose :GetConflicts do |args|
          args.declare :list, :map, :out, {}
        end
        
        # ModifyConflicts 
        # * command (sstr/I)
        #   Valid commands are 'ADD', 'REMOVE', 'UNION', 'INTERSECT', 'DIFF', and 'REPLACE'.
        # * conflicts (map/I)
        #   A set of other feature names that conflict with the feature
        def ModifyConflicts(command,conflicts,options={})
          # Print values of input parameters
          log.debug "ModifyConflicts: command => #{command}"
          log.debug "ModifyConflicts: conflicts => #{conflicts}"
        end
        
        expose :ModifyConflicts do |args|
          args.declare :command, :sstr, :in, {}
          args.declare :conflicts, :map, :in, {}
          args.declare :options, :map, :in, {}
        end
        
        # GetDepends 
        # * list (map/O)
        #   A list of other features that this feature depends on for proper operation, in priority order.
        def GetDepends()
          return FakeSet[*depends]
        end
        
        expose :GetDepends do |args|
          args.declare :list, :map, :out, {}
        end
        
        # ModifyDepends 
        # * command (sstr/I)
        #   Valid commands are 'ADD', 'REMOVE', and 'REPLACE'.
        # * depends (map/I)
        #   A list of other features a feature depends on, in priority order.  ADD adds deps to the end of this feature's deps, in the order supplied, REMOVE removes features from the dependency list, and REPLACE replaces the dependency list with the supplied list.
        def ModifyDepends(command,depends,options={})
          # Print values of input parameters
          log.debug "ModifyDepends: command => #{command}"
          log.debug "ModifyDepends: depends => #{depends}"
        end
        
        expose :ModifyDepends do |args|
          args.declare :command, :sstr, :in, {}
          args.declare :depends, :map, :in, {}
          args.declare :options, :map, :in, {}
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
        
        def apply_to(dict)
          self.GetParams.each do |k,v|
            dict[k] = v
          end
          dict
        end
        
        private
        include ArcUtils
        
        def depends
          find_arcs(FeatureArc,ArcLabel.depends_on('feature')) {|a| a.dest.name }
        end
        
        def conflicts
          find_arcs(FeatureArc,ArcLabel.conflicts_with('feature')) {|a| a.dest.name }
        end

        def includes
          find_arcs(FeatureArc,ArcLabel.inclusion('feature')) {|a| a.dest.name }
        end
        
        def depends=(deps)
          set_arcs(FeatureArc, ArcLabel.depends_on('feature'), deps, :find_first_by_name, :preserve_ordering=>true)
        end
        
        def conflicts=(conflicts)
          set_arcs(FeatureArc, ArcLabel.conflicts_with('feature'), conflicts, :find_first_by_name)
        end

        def includes=(deps)
          set_arcs(FeatureArc, ArcLabel.inclusion('feature'), deps, :find_first_by_name, :preserve_ordering=>true)
        end
        
      end
      
      class FeatureArc
        include ::Rhubarb::Persisting
        declare_column :source, :integer, :not_null, references(Feature, :on_delete=>:cascade)
        declare_column :dest, :integer, :not_null, references(Feature, :on_delete=>:cascade)
        declare_column :label, :integer, :not_null, references(ArcLabel)
      end
      
      class FeatureParams
        include ::Rhubarb::Persisting
        declare_column :feature, :integer, :not_null, references(Feature, :on_delete=>:cascade)
        declare_column :param, :integer, :not_null, references(Parameter, :on_delete=>:cascade)
        declare_column :value, :string
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
