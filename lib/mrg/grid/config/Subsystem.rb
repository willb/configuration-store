require 'spqr/spqr'

module Mrg
  module Grid
    module Config
      class Subsystem
        include ::SPQR::Manageable
        
        spqr_package 'mrg.grid.config'
        spqr_class 'Subsystem'
        # Find method (NB:  you must implement this)
        def Subsystem.find_by_id(objid)
          Subsystem.new
        end
        
# Find-all method (NB:  you must implement this)
        def Subsystem.find_all
          [Subsystem.new]
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
        
        # GetAttrs 
        # * attrs (map/O)
        # A set of parameter names that the subsystem is interested in
        def GetAttrs(args)
          # Assign values to out parameters
          args["attrs"] = args["attrs"]
        end
        
        spqr_expose :GetAttrs do |args|
          args.declare :attrs, :map, :out, {}
        end
        
        # ModifyAttrs 
        # * command (sstr/I)
        # Valid commands are 'ADD', 'REMOVE', 'UNION', 'INTERSECT', 'DIFF', and 'REPLACE'.
        # * attrs (map/I)
        # A set of parameter names
        def ModifyAttrs(args)
          # Print values of in parameters
          log.debug "command => #{args["command"]}" # 
          log.debug "attrs => #{args["attrs"]}" # 
        end
        
        spqr_expose :ModifyAttrs do |args|
          args.declare :command, :sstr, :in, {}
          args.declare :attrs, :map, :in, {}
        end
      end
    end
  end
end
