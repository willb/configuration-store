require 'spqr/spqr'
require 'rhubarb/rhubarb'
require 'mrg/grid/config/Parameter'
require 'mrg/grid/config/Subsystem'
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
          log.debug "GetName called on feature #{self.inspect}"
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
          log.debug "SetName: name => #{name.inspect}"
          raise "Feature name #{name} is taken" if (self.name != name and Feature.find_first_by_name(name))
          self.name = name
        end
        
        expose :SetName do |args|
          args.declare :name, :sstr, :in, {}
        end
        
        # GetFeatures 
        # * features (map/O)
        #   list of other feature names a feature includes
        def GetFeatures()
          log.debug "GetFeatures called on feature #{self.inspect}"
          return FakeList[*includes]
        end
        
        expose :GetFeatures do |args|
          args.declare :features, :map, :out, {}
        end
        
        # ModifyFeatures 
        # * command (sstr/I)
        #   Valid commands are 'ADD', 'REMOVE', and 'REPLACE'.
        # * features (map/I)
        #   A list of other feature names a feature includes
        def ModifyFeatures(command,features,options={})
          # Print values of input parameters
          log.debug "ModifyFeatures: command => #{command.inspect}"
          log.debug "ModifyFeatures: features => #{features.inspect}"
          log.debug "ModifyFeatures: options => #{options.inspect}"
          fl = FakeList.normalize(features).to_a
          
          modify_arcs(command,fl,options,:includes,:includes=,:explain=>"include",:preserve_order=>true,:xc=>:x_includes)
          DirtyElement.dirty_feature(self);
        end
        
        expose :ModifyFeatures do |args|
          args.declare :command, :sstr, :in, {}
          args.declare :features, :map, :in, {}
          args.declare :options, :map, :in, {}
        end
        
        # GetParams 
        # * params (map/O)
        #   A map(paramName, value) of parameters and their corresponding values that is specific to a group
        def GetParams()
          log.debug "GetParams called on feature #{self.inspect}"
          Hash[*FeatureParams.find_by(:feature=>self).map {|fp| [fp.param.name, fp.value]}.flatten]
        end
        
        expose :GetParams do |args|
          args.declare :params, :map, :out, {}
        end
        
        def GetParamsAsString
          log.debug "GetParamsAsString called on feature #{self.inspect}"
          hash = self.GetParams
          "{"+hash.map{|pair| "#{pair[0].inspect}:#{pair[1].inspect}"}.join(",")+"}"
        end
        
        expose :GetParamsAsString do |args|
          args.declare :params, :lstr, :out, {}
        end
        
        def AddParamMapping(param,value)
          log.debug "AddParam:  param => #{param.inspect}"
          log.debug "AddParam:  value => #{value.inspect}"
          
          self.ModifyParams("ADD", {param=>value})
        end

        expose :AddParamMapping do |args|
          args.declare :param, :sstr, :in, {}
          args.declare :value, :sstr, :in, {}
        end

        def RemoveParamMapping(param)
          log.debug "RemoveParam:  param => #{param.inspect}"
          
          self.ModifyParams("REMOVE", {param=>true})
        end

        expose :RemoveParamMapping do |args|
          args.declare :param, :sstr, :in, {}
        end
        
        def ClearParams
          log.debug "ClearParams called on feature #{self.inspect}"
          FeatureParams.find_by(:feature=>self).map {|fp| fp.delete}
          DirtyElement.dirty_feature(self);
          0
        end
        
        expose :ClearParams do |args|
          args.declare :ret, :int, :out, {}
        end
        
        # ModifyParams 
        # * command (sstr/I)
        #   Valid commands are 'ADD', 'REMOVE', and 'REPLACE'.
        # * params (map/I)
        #   A map(paramName, value) of parameters and their corresponding values that is specific to a group
        def ModifyParams(command,pvmap,options={})
          # Print values of input parameters
          log.debug "ModifyParams: command => #{command.inspect}"
          log.debug "ModifyParams: params => #{pvmap.inspect}"
          
          pvmap ||= {}
          
          params = pvmap.keys.map do |pn|
            prow = Parameter.find_first_by_name(pn)
            raise "invalid parameter #{pn}" unless prow
            prow
          end
          
          command = command.upcase
          
          case command
          when "ADD", "REMOVE" then
            params.each do |prow|
              pn = prow.name

              attributes = {:feature=>self, :param=>prow}

              # Delete any prior mappings for each supplied param in either case
              FeatureParams.find_by(attributes).map {|fp| fp.delete}
              
              if pvmap[pn].is_a? String
                attributes[:given_value] = pvmap[pn]
              else
                attributes[:uses_default] = true
              end
              
              # Add new mappings when requested
              FeatureParams.create(attributes) if command == "ADD"
            end
          when "REPLACE"
            self.ClearParams
            self.ModifyParams("ADD",pvmap,options)
          else raise ArgumentError.new("invalid command #{command}")
          end
          DirtyElement.dirty_feature(self);
        end
        
        expose :ModifyParams do |args|
          args.declare :command, :sstr, :in, {}
          args.declare :params, :map, :in, {}
          args.declare :options, :map, :in, {}
        end
        
        # GetConflicts 
        # * conflicts (map/O)
        #   A set of other features that this feature conflicts with
        def GetConflicts()
          log.debug "GetConflicts called on feature #{self.inspect}"
          return FakeSet[*conflicts]
        end
        
        expose :GetConflicts do |args|
          args.declare :conflicts, :map, :out, {}
        end
        
        # ModifyConflicts 
        # * command (sstr/I)
        #   Valid commands are 'ADD', 'REMOVE', 'UNION', 'INTERSECT', 'DIFF', and 'REPLACE'.
        # * conflicts (map/I)
        #   A set of other feature names that conflict with the feature
        def ModifyConflicts(command,conflicts,options={})
          # Print values of input parameters
          log.debug "ModifyConflicts: command => #{command.inspect}"
          log.debug "ModifyConflicts: conflicts => #{conflicts.inspect}"
          
          modify_arcs(command,conflicts.keys,options,:conflicts,:conflicts=,:explain=>"conflict with",:preserve_order=>true)
          DirtyElement.dirty_feature(self);
        end
        
        expose :ModifyConflicts do |args|
          args.declare :command, :sstr, :in, {}
          args.declare :conflicts, :map, :in, {}
          args.declare :options, :map, :in, {}
        end
        
        # GetDepends 
        # * depends (map/O)
        #   A list of other features that this feature depends on for proper operation, in priority order.
        def GetDepends()
          log.debug "GetDepends called on feature #{self.inspect}"
          return FakeList[*depends]
        end
        
        expose :GetDepends do |args|
          args.declare :depends, :map, :out, {}
        end
        
        # ModifyDepends 
        # * command (sstr/I)
        #   Valid commands are 'ADD', 'REMOVE', and 'REPLACE'.
        # * depends (map/I)
        #   A list of other features a feature depends on, in priority order.  ADD adds deps to the end of this feature's deps, in the order supplied, REMOVE removes features from the dependency list, and REPLACE replaces the dependency list with the supplied list.
        def ModifyDepends(command,depends,options={})
          # Print values of input parameters
          log.debug "ModifyDepends: command => #{command.inspect}"
          log.debug "ModifyDepends: depends => #{depends.inspect}"
          log.debug "ModifyDepends: options => #{options.inspect}"
          
          depends = FakeList.normalize(depends).to_a
          modify_arcs(command,depends,options,:depends,:depends=,:explain=>"depend on",:preserve_order=>true,:xc=>:x_depends)
          DirtyElement.dirty_feature(self);
        end
        
        expose :ModifyDepends do |args|
          args.declare :command, :sstr, :in, {}
          args.declare :depends, :map, :in, {}
          args.declare :options, :map, :in, {}
        end
        
        # GetSubsys 
        # * subsystems (map/O)
        #   A set of subsystem names that collaborate with the feature. This is used to determine subsystems that may need to be restarted if a configuration is changed
        def GetSubsys()
          log.debug "GetSubsys called on feature #{self.inspect}"
          return FakeSet[*subsystems]
        end
        
        expose :GetSubsys do |args|
          args.declare :subsystems, :map, :out, {}
        end
        
        # ModifySubsys 
        # * command (sstr/I)
        #   Valid commands are 'ADD', 'REMOVE', 'UNION', 'INTERSECT', 'DIFF', and 'REPLACE'.
        # * subsys (map/I)
        #   A set of subsystem names that collaborate with the feature. This is used to determine subsystems that may need to be restarted if a configuration is changed
        def ModifySubsys(command,subsys,options={})
          # Print values of input parameters
          log.debug "ModifySubsys: command => #{command.inspect}"
          log.debug "ModifySubsys: subsys => #{subsys.inspect}"

          modify_arcs(command,subsys.keys,options,:subsystems,:subsystems=,:explain=>"affect the subsystem")
          DirtyElement.dirty_feature(self);
        end
        
        expose :ModifySubsys do |args|
          args.declare :command, :sstr, :in, {}
          args.declare :subsys, :map, :in, {}
        end
        
        def apply_to(dict)
          includes.reverse_each do |ifname|
            included_feature = self.find_first_by_name(ifname)
            dict = included_feature.apply_to(dict)
          end
          
          self.GetParams.each do |k,v|
            dict[k] = v
          end
          dict
        end
        
        def x_includes(xtra = nil)
          xtra ||= []
          (includes | xtra).inject([]) do |acc,feat|
            acc << feat
            acc |= Feature.find_first_by_name(feat).x_includes
            acc
          end
        end
        
        def x_depends(xtra = nil)
          xtra ||= []
          (depends | xtra).inject([]) do |acc,feat|
            acc << feat
            acc |= Feature.find_first_by_name(feat).x_depends
            acc
          end
        end
        
        def Feature.features_for_node(n)
          fs = _features_for_node(n)
          fs.inject(fs) do |acc,feature|
            included_features = feature.x_includes.map {|fn| Feature.find_first_by_name(fn)}
            acc |= included_features
            acc
          end
        end
        
        def Feature.dependencies_for_node(n)
          features_for_node(n).map {|f| f.x_depends}.uniq.map {|fn| Feature.find_first_by_name(fn)}
        end
        
        declare_custom_query :_features_for_node, <<-QUERY
        SELECT * FROM __TABLE__ WHERE row_id IN (
          SELECT groupfeatures.feature AS f FROM groupfeatures, nodemembership WHERE nodemembership.grp = groupfeatures.grp AND nodemembership.node = ? UNION
          SELECT groupfeatures.feature AS f from groupfeatures, nodegroup WHERE nodegroup.name = "+++DEFAULT" AND groupfeatures.grp = nodegroup.row_id
        )
        QUERY
        
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
        
        def subsystems
          find_arcs(FeatureSubsys,ArcLabel.implication('subsystem')) {|a| a.dest.name }
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

        def subsystems=(deps)
          set_arcs(FeatureSubsys, ArcLabel.implication('subsystem'), deps, :find_first_by_name, :klass=>Subsystem)
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
        declare_column :given_value, :string
        declare_column :uses_default, :boolean, :default, :false
        def value
          return self.given_value unless self.uses_default
          self.param.default_val
        end
        
        def value=(val)
          self.given_value = val
        end
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
