# Feature:  QMF feature entity
#
# Copyright (c) 2009--2010 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'spqr/spqr'
require 'rhubarb/rhubarb'
require 'mrg/grid/config/Parameter'
require 'mrg/grid/config/ArcLabel'
require 'mrg/grid/config/ArcUtils'
require 'mrg/grid/config/DataValidating'

require 'set'

module Mrg
  module Grid
    module Config
      class Feature
        include ::Rhubarb::Persisting
        include ::SPQR::Manageable
        include DataValidating

        qmf_package_name 'com.redhat.grid.config'
        qmf_class_name 'Feature'
        ### Property method declarations
        # property uid uint32 
        
        declare_column :name, :string
        declare_index_on :name
        qmf_property :name, :sstr, :desc=>"This feature's name"
        
        def uid
          @row_id
        end
        
        def Feature.find_by_uid(u)
          find(u)
        end
        
        qmf_property :uid, :uint32, :index=>true
        ### Schema method declarations
        
        # setName 
        # * name (sstr/I)
        def setName(name)
          # Print values of input parameters
          log.debug "setName: name => #{name.inspect}"
          fail(Errors.make(Errors::NAME_ALREADY_IN_USE, Errors::FEATURE), "Feature name #{name} is taken") if (self.name != name and Feature.find_first_by_name(name))
          self.name = name
        end
        
        expose :setName do |args|
          args.declare :name, :sstr, :in, "A new name for this feature; this name must not already be in use by another feature."
        end
        
        # modifyIncludedFeatures 
        # * command (sstr/I)
        #   Valid commands are 'ADD', 'REMOVE', and 'REPLACE'.
        # * features (map/I)
        #   A list of other feature names a feature includes
        def modifyIncludedFeatures(command,features,options={})
          # Print values of input parameters
          log.debug "modifyFeatures: command => #{command.inspect}"
          log.debug "modifyFeatures: features => #{features.inspect}"
          log.debug "modifyFeatures: options => #{options.inspect}"
          fl = features
                    
          invalid_fl = Feature.select_invalid(fl)
          
          fail(Errors.make(Errors::NONEXISTENT_ENTITY, Errors::FEATURE), "Invalid features supplied for inclusion:  #{invalid_fl.inspect}") if invalid_fl != []
          
          do_validate = false
          new_includes = nil
          case command.upcase
          when "ADD" then
            do_validate = true
            new_includes = included_features | features
          when "REPLACE" then
            do_validate = true
            new_includes = features
          end
          
          validate_changes(:new_includes=>new_includes) if do_validate
          
          modify_arcs(command,fl,options,:included_features,:included_features=,:explain=>"include",:preserve_order=>true,:xc=>:x_includes)
          self_to_dirty_list
        end
        
        expose :modifyIncludedFeatures do |args|
          args.declare :command, :sstr, :in, "Valid commands are 'ADD', 'REMOVE', and 'REPLACE'."
          args.declare :features, :list, :in, "A list, in inverse priority order, of the names of features that this feature should include (in the case of ADD or REPLACE), or should not include (in the case of REMOVE)."
          args.declare :options, :map, :in, "No options are supported at this time."
        end
        
        qmf_property :params, :map, :desc=>"A map from parameter names to their values as set in this feature"
        qmf_property :param_meta, :map, :desc=>"A map from parameter names used in this feature to maps of metadata about those params"
        
        def clearParams
          log.debug "clearParams called on feature #{self.inspect}"
          FeatureParams.find_by(:feature=>self).map {|fp| fp.delete}
          self_to_dirty_list
          0
        end
        
        expose :clearParams do |args|
          args.declare :ret, :int, :out, "0 if successful."
        end
        
        # modifyParams 
        # * command (sstr/I)
        #   Valid commands are 'ADD', 'REMOVE', and 'REPLACE'.
        # * params (map/I)
        #   A map(paramName, value) of parameters and their corresponding values that is specific to a group
        def modifyParams(command,pvmap,options={})
          # Print values of input parameters
          log.debug "modifyParams: command => #{command.inspect}"
          log.debug "modifyParams: params => #{pvmap.inspect}"
          
          pvmap ||= {}
          
          # XXX: would be nice to use Parameter.select_invalid, but we don't want to look up each param twice
          invalid_params = []
          
          params = pvmap.keys.map do |pn|
            prow = Parameter.find_first_by_name(pn)
            invalid_params << pn unless prow
            prow
          end

          fail(Errors.make(Errors::NONEXISTENT_ENTITY, Errors::PARAMETER), "Invalid parameters supplied to feature #{self.name}:  #{invalid_params}") if invalid_params != []
          
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
            self.clearParams
            self.modifyParams("ADD",pvmap,options)
          else fail(Errors.make(Errors::BAD_COMMAND), "invalid command #{command}")
          end
          self_to_dirty_list
        end
        
        expose :modifyParams do |args|
          args.declare :command, :sstr, :in, "Valid commands are 'ADD', 'REMOVE', and 'REPLACE'."
          args.declare :params, :map, :in, "A map from parameter names to their corresponding values, as strings, for this feature.  To use the default value for a parameter, give it the value 0 (as an int)."
          args.declare :options, :map, :in, "No options are supported at this time."
        end
        

        qmf_property :conflicts, :list, :desc=>"A set of other features that this feature conflicts with"
        qmf_property :depends, :list, :desc=>"A list of other features that this feature depends on"
        qmf_property :included_features, :list, :desc=>"A list of other features that this feature includes, in priority order"
        
        # modifyConflicts 
        # * command (sstr/I)
        #   Valid commands are 'ADD', 'REMOVE', 'UNION', 'INTERSECT', 'DIFF', and 'REPLACE'.
        # * conflicts (map/I)
        #   A set of other feature names that conflict with the feature
        def modifyConflicts(command,conflicts,options={})
          # Print values of input parameters
          log.debug "modifyConflicts: command => #{command.inspect}"
          log.debug "modifyConflicts: conflicts => #{conflicts.inspect}"
          log.debug "modifyConflicts: options => #{options.inspect}"
          
          invalid_conflicts = Feature.select_invalid(conflicts)
          
          fail(Errors.make(Errors::NONEXISTENT_ENTITY, Errors::FEATURE), "Invalid features supplied for conflict:  #{invalid_conflicts.inspect}") if invalid_conflicts != []
          
          do_validate = false
          new_conflicts = nil
          case command.upcase
          when "ADD" then
            do_validate = true
            new_conflicts = self.conflicts | conflicts
          when "REPLACE" then
            do_validate = true
            new_conflicts = conflicts
          end
          
          validate_changes(:new_conflicts=>new_conflicts) if do_validate
          
          
          modify_arcs(command,conflicts,options,:conflicts,:conflicts=,:explain=>"conflict with",:preserve_order=>true)
          self_to_dirty_list
        end
        
        expose :modifyConflicts do |args|
          args.declare :command, :sstr, :in, "Valid commands are 'ADD', 'REMOVE', and 'REPLACE'."
          args.declare :conflicts, :list, :in, "A set of other feature names that conflict with the feature"
          args.declare :options, :map, :in, "No options are supported at this time."
        end
        
        # modifyDepends 
        # * command (sstr/I)
        #   Valid commands are 'ADD', 'REMOVE', and 'REPLACE'.
        # * depends (map/I)
        #   A list of other features a feature depends on, in priority order.  ADD adds deps to the end of this feature's deps, in the order supplied, REMOVE removes features from the dependency list, and REPLACE replaces the dependency list with the supplied list.
        def modifyDepends(command,depends,options={})
          # Print values of input parameters
          log.debug "modifyDepends: command => #{command.inspect}"
          log.debug "modifyDepends: depends => #{depends.inspect}"
          log.debug "modifyDepends: options => #{options.inspect}"
          
          invalid_deps = Feature.select_invalid(depends)
          
          fail(Errors.make(Errors::NONEXISTENT_ENTITY, Errors::FEATURE), "Invalid features supplied for dependency:  #{invalid_deps.inspect}") if invalid_deps != []
          
          do_validate = false
          new_depends = nil
          case command.upcase
          when "ADD" then
          do_validate = true
          new_depends = self.depends | depends
          when "REPLACE" then
          do_validate = true
          new_depends = depends
          end

          validate_changes(:new_depends=>new_depends) if do_validate
          
          modify_arcs(command,depends,options,:depends,:depends=,:explain=>"depend on",:preserve_order=>true,:xc=>:x_depends)
          self_to_dirty_list
        end
        
        expose :modifyDepends do |args|
          args.declare :command, :sstr, :in, "Valid commands are 'ADD', 'REMOVE', and 'REPLACE'."
          args.declare :depends, :list, :in, "A list of other features a feature depends on, in priority order.  ADD adds deps to the end of this feature's deps, in the order supplied, REMOVE removes features from the dependency list, and REPLACE replaces the dependency list with the supplied list."
          args.declare :options, :map, :in, "No options are supported at this time."
        end
        
        def apply_to(dict)
          included_features.reverse_each do |ifname|
            included_feature = self.class.find_first_by_name(ifname)
            dict = included_feature.apply_to(dict)
          end
          
          self.params.each do |k,v|
            if (v && v.slice(/^>=/))
              while v.slice!(/^>=/) ;  v.strip! ; end
              dict[k] = dict.has_key?(k) ? "#{dict[k]}, #{v.strip}" : "#{v.strip}"
            else
              dict[k] = v unless (dict.has_key?(k) && (!v || v == ""))
            end
          end
          dict
        end
        
        def x_includes(xtra = nil)
          xtra ||= []
          (included_features | xtra).inject([]) do |acc,feat|
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
          expand_includes(_features_for_node(n))
        end
        
        def Feature.dependencies_for_node(n)
          expand_deps(features_for_node(n))
        end
        
        def Feature.features_for_group(g)
          expand_includes(_features_for_group(g))
        end
        
        def Feature.dependencies_for_group(g)
          expand_deps(features_for_group(g))
        end

        def Feature.expand_deps(fs)
          fs.map {|f| f.x_depends}.flatten.uniq.map {|fn| Feature.find_first_by_name(fn)}
        end

        def Feature.expand_includes(fs)
          fs.inject(fs) do |acc,feature|
            included_features = feature.x_includes.map {|fn| Feature.find_first_by_name(fn)}
            acc |= included_features
            acc
          end
        end
        
        declare_custom_query :_features_for_group, <<-QUERY
        SELECT * from __TABLE__ WHERE row_id IN (
          SELECT feature from groupfeatures WHERE grp = ?
        )
        QUERY
        
        declare_custom_query :_features_for_node, <<-QUERY
        SELECT * FROM __TABLE__ WHERE row_id IN (
          SELECT groupfeatures.feature AS f FROM groupfeatures, nodemembership WHERE nodemembership.grp = groupfeatures.grp AND nodemembership.node = ? UNION
          SELECT groupfeatures.feature AS f from groupfeatures, nodegroup WHERE nodegroup.name = "+++DEFAULT" AND groupfeatures.grp = nodegroup.row_id
        )
        QUERY
        
        declare_custom_query :immed_edge_to, <<-QUERY
        SELECT * FROM __TABLE__ WHERE row_id IN (SELECT source FROM featurearc WHERE dest = :dest and label = :label)
        QUERY
        
        def depends
          find_arcs(FeatureArc,ArcLabel.depends_on('feature')) {|a| a.dest.name }
        end
        
        def conflicts
          find_arcs(FeatureArc,ArcLabel.conflicts_with('feature')) {|a| a.dest.name }
        end

        def included_features
          find_arcs(FeatureArc,ArcLabel.inclusion('feature')) {|a| a.dest.name }
        end
        
        def params
          Hash[*FeatureParams.find_by(:feature=>self).map {|fp| [fp.param.name, fp.value]}.flatten]
        end
        
        def param_meta
          Hash[*FeatureParams.find_by(:feature=>self).map {|fp| [fp.param.name, {"uses_default"=>fp.uses_default, "given_value"=>fp.given_value}]}.flatten]
        end
        
        def included_by
          Feature.immed_edge_to(:dest=>self.row_id, :label=>ArcLabel.inclusion('feature').row_id)
        end
        
        def x_included_by(xtra_fs=[])
          result = included_by
          result.dup.each do |f|
            result |= f.send(:x_included_by)
          end
          result
        end
        
        def depended_on_by
          Feature.immed_edge_to(:dest=>self.row_id, :label=>ArcLabel.depends_on('feature').row_id)
        end
        
        def x_depended_on_by(xtra_fs=[])
          result = depended_on_by
          result.dup.each do |f|
            result |= f.send(:x_depended_on_by)
          end
          result
        end
        
        private
        include ArcUtils
        
        def lookup(fs)
          fs.map {|fn| fn.is_a?(Feature) ? fn : Feature.find_first_by_name(fn)}.compact
        end
        
        # convenience method to mark this dirty as well as any feature that includes this
        def self_to_dirty_list
          DirtyElement.dirty_feature(self)
          included_by.each {|feature| feature.send(:self_to_dirty_list)}
        end
        
        def validate_changes(options=nil)
          # check to make sure that these changes won't break the existing configuration, on several axes:
          # ["immediately", "transitively"].each do |first|
          #   ["an immediate", "a transitive"].each do |second|
          #     1.  if F #{first} conflicts with F', it should be impossible 
          #         to introduce #{second} inclusion or dependency from F to F'
          #     2.  if F' #{first} conflicts with F, it should be impossible 
          #         to introduce #{second} inclusion or dependency from F to F'
          #   end
          #   3.  if F #{first} includes or depends on F', it should be impossible 
          #       to introduce an immediate conflict from F to F'
          #   4.  if F' #{first} includes or depends on F, it should be impossible 
          #       to introduce an immediate conflict from F to F'
          # end
          
          # XXX: this method could use a few hours of refactoring
          options ||= {}
          [:new_includes, :new_depends, :new_conflicts].each {|option| options[option] ||= nil}
          
          immediate_includes = options[:new_includes] || included_features
          immediate_depends = options[:new_depends] || depends
          immediate_conflicts = options[:new_conflicts] || conflicts
          
          transitive_includes = immediate_includes.inject(Set.new) do |acc,inc| 
            feature, = lookup([inc])
            acc << feature
            acc |= Set[*lookup(feature.x_includes)]
            acc
          end.to_a
          
          transitive_depends = immediate_depends.inject(Set.new) do |acc,inc|
            feature, = lookup([inc])
            acc << feature
            acc |= Set[*lookup(feature.x_depends)]
            acc
          end.to_a
          
          transitively_carried_conflicts = lookup(transitive_includes | transitive_depends).inject(Set.new) {|acc,f| acc |= f.conflicts; acc}.to_a
          
          error_code = Errors.make(Errors::INVALID_RELATIONSHIP, Errors::FEATURE)
          
          ti_names = transitive_includes.map {|f| f.name}
          td_names = transitive_depends.map {|f| f.name}
          tcc_names = transitively_carried_conflicts.map {|f| f.name}
          xib_names = x_included_by.map {|f| f.name}
          xdub_names = x_depended_on_by.map {|f| f.name}
          xxib_names = lookup(xib_names).map {|f| [f.name] | f.x_includes | f.x_depends}.flatten.uniq
          xxdub_names = lookup(xdub_names).map {|f| [f.name] | f.x_includes | f.x_depends}.flatten.uniq
          
          {"immediately include"=>immediate_includes, 
           "immediately depend upon"=>immediate_depends, 
           "transitively include"=>ti_names, 
           "transitively depend upon"=>td_names,
           "be transitively included by"=>xib_names,
           "be transitively depended upon by"=>xdub_names,
           "be transitively included by a feature that transitively includes or depends on"=>xxib_names,
           "be transitively depended upon by a feature that transitively includes or depends on"=>xxdub_names
           }.each do |what, where|
             {"immediately conflict"=>immediate_conflicts, "transitively conflict (via an inclusion or dependency)"=>tcc_names}.each do |cwhat, cwhere|
               intersection = (where & cwhere).compact

               fail(error_code, "Feature #{name} cannot both #{what} and #{cwhat} with #{intersection.join(", ")}") if intersection != []
             end
          end
          
          
        end
        
        def depends=(deps)
          set_arcs(FeatureArc, ArcLabel.depends_on('feature'), deps, :find_first_by_name, :preserve_ordering=>true)
        end
        
        def conflicts=(conflicts)
          set_arcs(FeatureArc, ArcLabel.conflicts_with('feature'), conflicts, :find_first_by_name)
        end

        def included_features=(deps)
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
    end
  end
end
