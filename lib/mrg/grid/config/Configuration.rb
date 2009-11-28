require 'spqr/spqr'

module Mrg
  module Grid
    module Config
      class Configuration
        include ::SPQR::Manageable
        
        spqr_package 'mrg.grid.config'
        spqr_class 'Configuration'
        # Find method (NB:  you must implement this)
        def Configuration.find_by_id(objid)
          Configuration.new
        end
        
# Find-all method (NB:  you must implement this)
        def Configuration.find_all
          [Configuration.new]
        end
        ### Property method declarations
        
        # property uid uint32 
        def uid
          log.debug 'Requested property uid'
          nil
        end
        
        def uid=(val)
          log.debug 'Set property uid to #{val}'
          nil
        end
        
        spqr_property :uid, :uint32, :index=>true
        ### Schema method declarations
        
        # GetVersion 
        # * version (uint32/O)
        # 
        def GetVersion(args)
          # Assign values to out parameters
          args["version"] = args["version"]
        end
        
        spqr_expose :GetVersion do |args|
          args.declare :version, :uint32, :out, {}
        end
        
        # GetFeatures 
        # * list (map/O)
        # A set of features defined in this configuration
        def GetFeatures(args)
          # Assign values to out parameters
          args["list"] = args["list"]
        end
        
        spqr_expose :GetFeatures do |args|
          args.declare :list, :map, :out, {}
        end
        
        # GetCustomParams 
        # * params (map/O)
        # A map(paramName, value) of parameter/value pairs for a configuration
        def GetCustomParams(args)
          # Assign values to out parameters
          args["params"] = args["params"]
        end
        
        spqr_expose :GetCustomParams do |args|
          args.declare :params, :map, :out, {}
        end
        
        # ModifyCustomParams 
        # * command (sstr/I)
        # Valid commands are 'ADD', 'REMOVE', 'UNION', 'INTERSECT', 'DIFF', and 'REPLACE'.
        # * params (map/I)
        # map(groupId, map(param, value))
        def ModifyCustomParams(args)
          # Print values of in parameters
          log.debug "command => #{args["command"]}" # 
          log.debug "params => #{args["params"]}" # 
        end
        
        spqr_expose :ModifyCustomParams do |args|
          args.declare :command, :sstr, :in, {}
          args.declare :params, :map, :in, {}
        end
        
        # GetDefaultFeatures 
        # * features (map/O)
        # 
        def GetDefaultFeatures(args)
          # Assign values to out parameters
          args["features"] = args["features"]
        end
        
        spqr_expose :GetDefaultFeatures do |args|
          args.declare :features, :map, :out, {}
        end
        
        # ModifyDefaultFeatures 
        # * command (sstr/I)
        # Valid commands are 'ADD', 'REMOVE', 'UNION', 'INTERSECT', 'DIFF', and 'REPLACE'.
        # * features (map/I)
        # 
        def ModifyDefaultFeatures(args)
          # Print values of in parameters
          log.debug "command => #{args["command"]}" # 
          log.debug "features => #{args["features"]}" # 
        end
        
        spqr_expose :ModifyDefaultFeatures do |args|
          args.declare :command, :sstr, :in, {}
          args.declare :features, :map, :in, {}
        end
      end
    end
  end
end
