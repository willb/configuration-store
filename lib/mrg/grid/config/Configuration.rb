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
        
        # GetVersion 
        # * version (uint32/O)
        def GetVersion()
          # Assign values to output parameters
          version ||= 0
          # Return value
          return version
        end
        
        expose :GetVersion do |args|
          args.declare :version, :uint32, :out, {}
        end
        
        # GetFeatures 
        # * list (map/O)
        #   A set of features defined in this configuration
        def GetFeatures()
          # Assign values to output parameters
          list ||= {}
          # Return value
          return list
        end
        
        expose :GetFeatures do |args|
          args.declare :features, :map, :out, {}
        end
        
        # GetCustomParams 
        # * params (map/O)
        #   A map(paramName, value) of parameter/value pairs for a configuration
        def GetCustomParams()
          # Assign values to output parameters
          params ||= {}
          # Return value
          return params
        end
        
        expose :GetCustomParams do |args|
          args.declare :params, :map, :out, {}
        end
        
        # ModifyCustomParams 
        # * command (sstr/I)
        #   Valid commands are 'ADD', 'REMOVE', 'UNION', 'INTERSECT', 'DIFF', and 'REPLACE'.
        # * params (map/I)
        #   map(groupId, map(param, value))
        def ModifyCustomParams(command,params)
          # Print values of input parameters
          log.debug "ModifyCustomParams: command => #{command.inspect}"
          log.debug "ModifyCustomParams: params => #{params.inspect}"
        end
        
        expose :ModifyCustomParams do |args|
          args.declare :command, :sstr, :in, {}
          args.declare :params, :map, :in, {}
        end
        
        # GetDefaultFeatures 
        # * features (map/O)
        def GetDefaultFeatures()
          # Assign values to output parameters
          features ||= {}
          # Return value
          return features
        end
        
        expose :GetDefaultFeatures do |args|
          args.declare :features, :map, :out, {}
        end
        
        # ModifyDefaultFeatures 
        # * command (sstr/I)
        #   Valid commands are 'ADD', 'REMOVE', 'UNION', 'INTERSECT', 'DIFF', and 'REPLACE'.
        # * features (map/I)
        def ModifyDefaultFeatures(command,features)
          # Print values of input parameters
          log.debug "ModifyDefaultFeatures: command => #{command.inspect}"
          log.debug "ModifyDefaultFeatures: features => #{features.inspect}"
        end
        
        expose :ModifyDefaultFeatures do |args|
          args.declare :command, :sstr, :in, {}
          args.declare :features, :map, :in, {}
        end
      end
    end
  end
end
