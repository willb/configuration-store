require 'spqr/spqr'

module Mrg
  module Grid
    module Config
      class Node
        include ::SPQR::Manageable
        
        spqr_package 'mrg.grid.config'
        spqr_class 'Node'
        # Find method (NB:  you must implement this)
        def Node.find_by_id(objid)
          Node.new
        end
        
# Find-all method (NB:  you must implement this)
        def Node.find_all
          [Node.new]
        end
        ### Property method declarations
        
        # property name sstr 
        def name
          log.debug 'Requested property name'
          nil
        end
        
        def name=(val)
          log.debug 'Set property name to #{val}'
          nil
        end
        
        spqr_property :name, :sstr, :index=>true
        ### Schema method declarations
        
        # GetPool 
        # * pool (sstr/O)
        # 
        def GetPool(args)
          # Assign values to out parameters
          args["pool"] = args["pool"]
        end
        
        spqr_expose :GetPool do |args|
          args.declare :pool, :sstr, :out, {}
        end
        
        # SetPool 
        # * pool (sstr/I)
        # 
        def SetPool(args)
          # Print values of in parameters
          log.debug "pool => #{args["pool"]}" # 
        end
        
        spqr_expose :SetPool do |args|
          args.declare :pool, :sstr, :in, {}
        end
        
        # GetLastCheckinTime 
        # * time (uint32/O)
        # 
        def GetLastCheckinTime(args)
          # Assign values to out parameters
          args["time"] = args["time"]
        end
        
        spqr_expose :GetLastCheckinTime do |args|
          args.declare :time, :uint32, :out, {}
        end
        
        # GetConfig 
        # * config (map/O)
        # A map(parameter, value) representing the configuration for the node supplied
        def GetConfig(args)
          # Assign values to out parameters
          args["config"] = args["config"]
        end
        
        spqr_expose :GetConfig do |args|
          args.declare :config, :map, :out, {}
        end
        
        # CheckConfigVersion 
        # * version (uint32/I)
        # 
        def CheckConfigVersion(args)
          # Print values of in parameters
          log.debug "version => #{args["version"]}" # 
        end
        
        spqr_expose :CheckConfigVersion do |args|
          args.declare :version, :uint32, :in, {}
        end
      end
    end
  end
end
