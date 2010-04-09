# Configuration:  QMF configuration entity
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

module Mrg
  module Grid
    module Config
      class Configuration
        include ::Rhubarb::Persisting
        include ::SPQR::Manageable

        qmf_package_name 'mrg.grid.config'
        qmf_class_name 'Configuration'
        ### Property method declarations
        # property uid uint32 

        declare_column :uid, :integer, :not_null
        declare_index_on :uid
        
        qmf_property :uid, :uint32, :index=>true
        ### Schema method declarations
        
        # getVersion 
        # * version (uint32/O)
        def getVersion()
          # Assign values to output parameters
          version ||= 0
          # Return value
          return version
        end
        
        expose :getVersion do |args|
          args.declare :version, :uint32, :out, {}
        end
        
        # getFeatures 
        # * list (map/O)
        #   A set of features defined in this configuration
        def getFeatures()
          # Assign values to output parameters
          list ||= {}
          # Return value
          return list
        end
        
        expose :getFeatures do |args|
          args.declare :features, :map, :out, {}
        end
        
        # getCustomParams 
        # * params (map/O)
        #   A map(paramName, value) of parameter/value pairs for a configuration
        def getCustomParams()
          # Assign values to output parameters
          params ||= {}
          # Return value
          return params
        end
        
        expose :getCustomParams do |args|
          args.declare :params, :map, :out, {}
        end
        
        # modifyCustomParams 
        # * command (sstr/I)
        #   Valid commands are 'ADD', 'REMOVE', 'UNION', 'INTERSECT', 'DIFF', and 'REPLACE'.
        # * params (map/I)
        #   map(groupId, map(param, value))
        def modifyCustomParams(command,params)
          # Print values of input parameters
          log.debug "modifyCustomParams: command => #{command.inspect}"
          log.debug "modifyCustomParams: params => #{params.inspect}"
        end
        
        expose :modifyCustomParams do |args|
          args.declare :command, :sstr, :in, {}
          args.declare :params, :map, :in, {}
        end
        
        # getDefaultFeatures 
        # * features (map/O)
        def getDefaultFeatures()
          # Assign values to output parameters
          features ||= {}
          # Return value
          return features
        end
        
        expose :getDefaultFeatures do |args|
          args.declare :features, :map, :out, {}
        end
        
        # modifyDefaultFeatures 
        # * command (sstr/I)
        #   Valid commands are 'ADD', 'REMOVE', 'UNION', 'INTERSECT', 'DIFF', and 'REPLACE'.
        # * features (map/I)
        def modifyDefaultFeatures(command,features)
          # Print values of input parameters
          log.debug "modifyDefaultFeatures: command => #{command.inspect}"
          log.debug "modifyDefaultFeatures: features => #{features.inspect}"
        end
        
        expose :modifyDefaultFeatures do |args|
          args.declare :command, :sstr, :in, {}
          args.declare :features, :map, :in, {}
        end
      end
    end
  end
end
