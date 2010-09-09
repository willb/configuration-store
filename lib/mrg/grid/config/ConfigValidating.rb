# Validating.rb:  mixin for validating configurations on nodes or groups
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

module Mrg
  module Grid
    module Config
      # forward declaration
      class ConfigVersions
      end
      
      class DummyCache
        attr_reader :nodes, :features, :groups, :parameters
        
        def initialize
          @nodes = Hash.new {|h,k| h[k] = Node.find_first_by_name(k)}
          @features = Hash.new {|h,k| h[k] = Feature.find_first_by_name(k)}
          @groups = Hash.new {|h,k| h[k] = Group.find_first_by_name(k)}
          @parameters = Hash.new {|h,k| h[k] = Parameter.find_first_by_name(k)}
        end
        
        def find_instance(klass, name)
          cname = classname(klass)
          self.send("#{cname.downcase}s")[name]
        end
        
        def features_for(klass, instance)
          cname = classname(klass)
          Feature.send("features_for_#{cname.downcase}", instance)
        end
        
        def parameters_for(klass, instance)
          cname = classname(klass)
          Parameter.send("s_for_#{cname.downcase}", instance)          
        end
        
        def feature_dependencies_for(klass, instance)
          generic_dependencies_for(Feature, klass, instance)
        end
        
        def parameter_dependencies_for(klass, instance)
          generic_dependencies_for(Parameter, klass, instance)          
        end
        
        private
        
        def generic_dependencies_for(base_class, arg_class, instance)
          cname = classname(arg_class)
          base_class.send("dependencies_for_#{cname.downcase}", instance)
        end
        
        def classname(klass)
          (klass.name.to_s =~ /(Node|Feature|Group|Parameter)$/ ; $~.to_s)
        end
      end

      class ConfigDataCache
        attr_reader :nodes, :features, :groups, :parameters

        def self.reopen_proxy_class(klass)
          # add a method_missing to klass that calls (and caches) 
          # the results of invoking the missing method on 
          # self.original_object

          # add class-specific caching methods also
        end

        def self.cache_proxy_class_for(klass)
          @proxy_classes ||= Hash.new do |h,k|
            h[k] = reopen_proxy_class(Struct.new("#{klass.name.to_s}CacheProxy", *klass.colnames + [:original_object]))
          end
          @proxy_classes[klass]
        end
        
        def self.clonePersistingObject(obj)
          klass = cache_proxy_class_for(obj.class)
          instance = klass.new(*obj.class.colnames.map {|msg| obj.send(msg)})
          instance.original_object = obj
          instance
        end
        
        
      end


      module ConfigValidating
        
        BROKEN_FEATURE_DEPS = "Unsatisfied feature dependencies"
        UNSET_MUSTCHANGE_PARAMS = "Unset necessary parameters"
        BROKEN_PARAM_DEPS = "Unsatisfied parameter dependencies"
        PARAM_CONFLICTS = "Conflicting parameters"
        FEATURE_CONFLICTS = "Conflicting features"

        
        # Validate ensures the following for a given node or group NG:
        #  1.  if NG enables some feature F that depends on F', NG must also include F', 
        #        enable F', or enable some feature F'' that includes F'
        #  2.  if NG enables some feature F that depends on some param P being set,
        #        NG must provide a value for P
        #  3.  if NG sets some param P that depends on some other param P',
        #        NG must also set P'
        #    
        #  Other consistency properties are ensured by other parts of the store (e.g.
        #  that a group does not enable conflicting features).  Returns true if the
        #  configuration is valid, or an explanation if it is not.
        
        def validate(options=nil)
          options ||= {}
          save_for_version = options[:save_for_version]
          cache = options[:cache] || DummyCache.new
          
          cached_class = self.class
          cached_self = cache.find_instance(cached_class, self.name)
          
          my_config = cached_self.getConfig  # FIXME: it would be nice to not calculate this redundantly
          
          if save_for_version
            updated_config = my_config.dup
            updated_config["WALLABY_CONFIG_VERSION"] = save_for_version.to_s
            cv = ConfigVersion[save_for_version]
            cv[self.name] = updated_config
          end
          
          log.debug {"in #{(self.class.name.to_s =~ /(Node|Feature|Group|Parameter)$/ ; $~.to_s)}#validate for #{self.name}..."}
          
          dfn = cache.feature_dependencies_for(cached_class, cached_self).map {|f| f.name}
          log.debug "dependencies for #{self.name} is #{dfn}"
          
          features_for_entity = cache.features_for(cached_class, cached_self)
          params_for_entity = my_config.keys.map {|pn| cache.parameters[pn] }.compact
          
          feature_conflicts = identify_conflicts(features_for_entity)
          param_conflicts = identify_conflicts(params_for_entity)
          
          ffn = features_for_entity.map {|f| f.name}
          log.debug "features for #{self.name} is #{ffn}"
          
          orphaned_deps = (dfn - ffn).reject {|f| f == nil }
          unset_params = my_unset_params(my_config)
          my_params = cache.parameters_for(cached_class, cached_self)
          my_param_deps = cache.parameter_dependencies_for(cached_class, cached_self)
          orphaned_params = my_param_deps - my_params
          
          return true if orphaned_deps == [] && unset_params == [] && orphaned_params == [] && param_conflicts == [] && feature_conflicts == []
          
          result = {}
          result[BROKEN_FEATURE_DEPS] = orphaned_deps.uniq if orphaned_deps != []
          result[UNSET_MUSTCHANGE_PARAMS] = unset_params.uniq if unset_params != []
          result[BROKEN_PARAM_DEPS] = orphaned_params.uniq if orphaned_params != []
          result[PARAM_CONFLICTS] = param_conflicts if param_conflicts != []
          result[FEATURE_CONFLICTS] = feature_conflicts if feature_conflicts != []
          
          [self.name, result]
        end

        def my_unset_params(my_config = nil)
          my_config ||= self.getConfig
          mc_params = Parameter.s_that_must_change
          (my_config.keys & mc_params.keys).inject([]) do |acc,param|
            dv = Parameter.find_first_by_name(param).default_val
            acc << param if my_config[param] == dv
            acc
          end
        end
        
        def identify_conflicts(things)
          conflicts_to = Hash.new {|h,v| h[v] = [] }
          conflict_horizon = Set.new
          sources = Set.new
          
          things.each do |thing|
            sources << thing.name
            conflict_horizon |= thing.conflicts
            
            thing.conflicts.each do |conf|
              conflicts_to[conf] << thing.name
            end
          end
          
          conflicting_things = (sources & conflict_horizon)
          
          if conflicting_things.size > 0
            result = []
            conflicting_things.each do |to|
              result |= conflicts_to[to].map {|from| [from, to].sort}
            end
            
            return result
          end
          
          []
        end
        
        def self.included(base)
          base.instance_eval do
            private :my_unset_params
            private :identify_conflicts
          end
        end
      end
    end
  end
end