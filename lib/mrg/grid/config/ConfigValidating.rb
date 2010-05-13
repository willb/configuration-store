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
      
      module ConfigValidating
        
        BROKEN_FEATURE_DEPS = "Unsatisfied feature dependencies"
        UNSET_MUSTCHANGE_PARAMS = "Unset necessary parameters"
        BROKEN_PARAM_DEPS = "Unsatisfied parameter dependencies"

        
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
          
          my_config = self.getConfig  # FIXME: it would be nice to not calculate this redundantly
          
          if save_for_version
            updated_config = my_config.dup
            updated_config["WALLABY_CONFIG_VERSION"] = save_for_version.to_s
            cv = ConfigVersion[save_for_version]
            cv[self.name] = updated_config
          end
            
          classname = self.class.name.split("::")[-1]
          log.debug "in #{classname}#validate for #{self.name}..."
          
          dependency_msg = "dependencies_for_#{classname.downcase}".to_sym
          feature_msg = "features_for_#{classname.downcase}".to_sym
          param_msg = "s_for_#{classname.downcase}".to_sym
          
          dfn = Feature.send(dependency_msg, self).map {|f| f.name}
          log.debug "dependencies for #{self.name} is #{dfn}"
          
          ffn = Feature.send(feature_msg, self).map {|f| f.name}
          log.debug "features for #{self.name} is #{ffn}"
          
          orphaned_deps = (dfn - ffn).reject {|f| f == nil }
          unset_params = my_unset_params(my_config)
          my_params = Parameter.send(param_msg, self)
          my_param_deps = Parameter.send(dependency_msg, self, my_params)
          orphaned_params = my_param_deps - my_params
          
          return true if orphaned_deps == [] && unset_params == [] && orphaned_params == []
          
          result = {}
          result[BROKEN_FEATURE_DEPS] = orphaned_deps.uniq if orphaned_deps != []
          result[UNSET_MUSTCHANGE_PARAMS] = unset_params.uniq if unset_params != []
          result[BROKEN_PARAM_DEPS] = orphaned_params.uniq if orphaned_params != []
          
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
        
        def self.included(base)
          base.instance_eval do
            private :my_unset_params
          end
        end
      end
    end
  end
end
