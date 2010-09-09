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
          # add class-specific caching methods

          if klass.name =~ /(Feature|Parameter)CacheProxy$/
            klass.class_eval do
              def conflicts
                @__my_conflicts ||= original_object.conflicts
              end
              
              def conflicts=(cfs)
                @__my_conflicts = cfs
              end
            end
          end
          
          if klass.name =~ /FeatureCacheProxy$/
            klass.class_eval do
              def included_features
                @__my_included_features ||= original_object.included_features
              end
              
              def params
                @__my_params ||= original_object.params
              end
              
              def apply_to(dict)
                included_features.reverse_each do |ifname|
                  included_feature = containing_cache.features[ifname]
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
            end
          end
          
          if klass.name =~ /GroupCacheProxy$/
            klass.class_eval do
              def getConfig
                @__my_config ||= original_object.getConfig
              end
              
              def config=(cfg)
                @__my_config = cfg
              end

              def feature_objs
                @__my_feature_objs ||= original_object.features.map {|fn| containing_cache.features[fn]}
              end

              def params
                @__my_params ||= original_object.params
              end
              
              def apply_to(config)
                feature_objs.reverse_each do |feature|
                  config = feature.apply_to(config)
                end

                # apply group-specific param settings
                # XXX: doesn't check for null-v; is this a problem (not in practice, maybe in theory)
                params.each do |k,v|
                  if (v && v.slice!(/^>=/))
                    while v.slice!(/^>=/) ;  v.strip! ; end
                    config[k] = (config.has_key?(k) && config[k]) ? "#{ss_prepend}#{config[k]}, #{v.strip}" : "#{ss_prepend}#{v.strip}"
                  else
                    config[k] = v
                  end
                end

                config
              end
              
            end
          end
          
          if klass.name =~ /NodeCacheProxy$/
            klass.class_eval do
              def getConfig
                return @__my_config if @__my_config
                
                @__my_config = containing_cache.groups[Group.DEFAULT_GROUP.name].getConfig.dup
                # strip StringSet markers from default group config
                @__my_config.each do |(k,v)|
                  v.slice!(/^>=/) if v
                  @__my_config[k] = v && v.strip
                end

                db_memberships.reverse_each do |grp|
                  @__my_config = grp.apply_to(@__my_config)
                end

                @__my_config = self.idgroup.apply_to(@__my_config) if self.idgroup

                @__my_config                
              end
              
              def idgroup
                @__my_idgroup ||= containing_cache.groups[original_object.identity_group.name]
              end
              
              def memberships
                @__my_memberships ||= original_object.memberships
              end
              
              def db_memberships
                @__my_db_memberships ||= memberships.map {|grp| containing_cache.groups[grp]}
              end
              
            end
          end

          klass
        end

        def self.cache_proxy_class_for(klass)
          @proxy_classes ||= Hash.new do |h,key|
            basename = (key =~ /[^:]+$/ ; $~.to_s)
            kls = ::Mrg::Grid::Config.const_get(basename)
            h[key] = reopen_proxy_class(Struct.new("#{basename}CacheProxy", *kls.colnames + [:original_object, :containing_cache]))
          end
          @proxy_classes[klass.name]
        end
        
        def self.proxy_classes
          @proxy_classes
        end
        
        def clone_persisting_object(obj)
          return nil if obj == nil
          klass = ConfigDataCache.cache_proxy_class_for(obj.class)
          unless klass
            raise RuntimeError.new("FATAL:  #{obj.class.inspect} not found in #{ConfigDataCache.proxy_classes.inspect}")
          end
          instance = klass.new
          obj.class.colnames.each {|msg| instance.send("#{msg}=", obj.send(msg))}
          instance.original_object = obj
          instance.containing_cache = self
          instance
        end
        
        def find_instance(klass, name)
          name = name.name if name.respond_to?(:name)
          puts "trying to find #{klass.inspect}:#{name}" if $XXDEBUG
          cname = classname(klass)
          self.send("#{cname.downcase}s")[name]
        end
        
        def initialize(*nodelist)
          @parameters = Hash.new {|h,k| h[k] = clone_persisting_object(Parameter.find_first_by_name(k))}
          @features = Hash.new {|h,k| h[k] = clone_persisting_object(Feature.find_first_by_name(k))}
          @groups = Hash.new {|h,k| h[k] = clone_persisting_object(Group.find_first_by_name(k))}
          @nodes = Hash.new {|h,k| h[k] = clone_persisting_object(Node.find_first_by_name(k))}
          
          features_of_interest = Set.new
          parameters_of_interest = Set.new
          groups_of_interest = Set.new
          
          feature_inclusions = Mrg::Grid::Util::Graph.new
          feature_dependencies = Mrg::Grid::Util::Graph.new
          param_dependencies = Mrg::Grid::Util::Graph.new
          
          entity_features_and_params = Mrg::Grid::Util::Graph.new
          
          groups_of_interest << @groups[Group.DEFAULT_GROUP.name]
          
          FeatureArc.find_by(:label=>ArcLabel.inclusion('feature').row_id).each do |fa|
            entity_features_and_params.add_edge(@features[fa.source.name], @features[fa.dest.name], "feature-includes-feature")
            feature_inclusions.add_edge(@features[fa.source.name], @features[fa.dest.name], "feature-includes-feature")
            feature_dependencies.add_edge(@features[fa.source.name], @features[fa.dest.name], "feature-includes-feature")
          end
          
          FeatureArc.find_by(:label=>ArcLabel.depends_on('feature').row_id).each do |fa|
            feature_dependencies.add_edge(@features[fa.source.name], @features[fa.dest.name]) if fa.label == ArcLabel.depends_on('feature')
          end
          
          ParameterArc.find_by(:label=>ArcLabel.depends_on('param').row_id).each do |pa|
            param_dependencies.add_edge(@parameters[pa.source.name], @parameters[pa.dest.name])
          end
          
          @feature_inclusions = ::Mrg::Grid::Util::Graph::DagTransitiveClosure.new(feature_inclusions).xc
          @feature_dependencies = ::Mrg::Grid::Util::Graph::DagTransitiveClosure.new(feature_dependencies).xc
          @param_dependencies = ::Mrg::Grid::Util::Graph::DagTransitiveClosure.new(param_dependencies).xc
          
          if nodelist == [Group.DEFAULT_GROUP]
            nodelist = []
          else
            nodelist.each do |node|
              cloned_node = @nodes[node.name]
              
              groups_of_interest |= cloned_node.db_memberships.map do |group|
                entity_features_and_params.add_edge(cloned_node, group, "node-is-a-member-of-group")
                group
              end
              
              groups_of_interest << cloned_node.idgroup
              entity_features_and_params.add_edge(cloned_node, cloned_node.idgroup, "node-is-a-member-of-group")
              entity_features_and_params.add_edge(cloned_node, @groups[Group.DEFAULT_GROUP.name], "node-is-a-member-of-group")
            end
          end
          
          groups_of_interest.each do |group|
            group.feature_objs.each do |feature|
              features_of_interest << feature
              puts "group #{group.name} enables feature #{feature.name}"if $XXDEBUG
              entity_features_and_params.add_edge(group, feature, "group-enables-feature")
            end
            
            group.params.keys.each do |param|
              entity_features_and_params.add_edge(group, param, "group-sets-param")
            end
          end
          
          features_of_interest.each do |feature|
            feature.params.keys.each do |param|
              entity_features_and_params.add_edge(feature, param, "feature-sets-param")
            end
          end
          
          @entity_features_and_params = ::Mrg::Grid::Util::Graph::DagTransitiveClosure.new(entity_features_and_params).xc
        end
        
        
        def features_for(klass, instance)
          obj = find_instance(klass, instance)
          unless obj
            raise RuntimeError.new("couldn't find a #{klass.inspect} instance named #{instance.inspect}")
          end
          @features_for ||= {}
          @features_for[obj] ||= @entity_features_and_params[obj].select {|vertex| vertex.class.name =~ /FeatureCacheProxy$/}.to_a
          puts "features_for[#{obj.name}] ==> #{@features_for[obj].inspect}" if $XXDEBUG
          @features_for[obj]
        end
        
        def parameters_for(klass, instance)
          obj = find_instance(klass, instance)
          @parameters_for ||= {}
          @parameters_for[obj] ||= @entity_features_and_params[obj].select {|vertex| vertex.class.name =~ /ParameterCacheProxy$/}.to_a
        end
        
        def feature_dependencies_for(klass, instance)
          result = Set[*features_for(klass, instance)]
          result.inject(result) do |acc, ent|
            acc |= @feature_dependencies[ent]
          end.to_a
        end
        
        def parameter_dependencies_for(klass, instance)
          result = Set[*parameters_for(klass, instance)]
          result.inject(result) do |acc, ent|
            acc |= @param_dependencies[ent]
          end.to_a
        end
        
        
        private
        def classname(klass)
          (klass.name.to_s =~ /(Node|Feature|Group|Parameter)$/ ; $~.to_s)
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
            updated_config = my_config
            updated_config["WALLABY_CONFIG_VERSION"] = save_for_version.to_s
            cv = ConfigVersion[save_for_version]
            cv[self.name] = updated_config
          end
          
          log.debug {"in #{(self.class.name.to_s =~ /(Node|Feature|Group|Parameter)$/ ; $~.to_s)}#validate for #{self.name}..."}
          
          dfn = cache.feature_dependencies_for(cached_class, cached_self).compact.map {|f| f.name}
          
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