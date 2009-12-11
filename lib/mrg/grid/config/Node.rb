require 'spqr/spqr'
require 'rhubarb/rhubarb'

module Mrg
  module Grid
    module Config
      class Node
        include ::Rhubarb::Persisting
        include ::SPQR::Manageable

        qmf_package_name 'mrg.grid.config'
        qmf_class_name 'Node'
        ### Property method declarations
        # property name sstr 

        declare_column :name, :string, :not_null
        declare_index :name
        
        qmf_property :name, :sstr, :index=>true
        ### Schema method declarations
        
        # GetPool 
        # * pool (sstr/O)
        def GetPool()
          # Assign values to output parameters
          pool ||= ""
          # Return value
          return pool
        end
        
        expose :GetPool do |args|
          args.declare :pool, :sstr, :out, {}
        end
        
        # SetPool 
        # * pool (sstr/I)
        def SetPool(pool)
          # Print values of input parameters
          log.debug "SetPool: pool => #{pool}"
        end
        
        expose :SetPool do |args|
          args.declare :pool, :sstr, :in, {}
        end
        
        # GetLastCheckinTime 
        # * time (uint32/O)
        def GetLastCheckinTime()
          # Assign values to output parameters
          time ||= 0
          # Return value
          return time
        end
        
        expose :GetLastCheckinTime do |args|
          args.declare :time, :uint32, :out, {}
        end
        
        # GetConfig 
        # * config (map/O)
        #   A map(parameter, value) representing the configuration for the node supplied
        def GetConfig()
          # Assign values to output parameters
          config ||= {}
          # Return value
          return config
        end
        
        expose :GetConfig do |args|
          args.declare :config, :map, :out, {}
        end
        
        # CheckConfigVersion 
        # * version (uint32/I)
        def CheckConfigVersion(version)
          # Print values of input parameters
          log.debug "CheckConfigVersion: version => #{version}"
        end
        
        expose :CheckConfigVersion do |args|
          args.declare :version, :uint32, :in, {}
        end
      end
    end
  end
end
