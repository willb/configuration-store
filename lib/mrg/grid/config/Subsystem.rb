require 'spqr/spqr'
require 'rhubarb/rhubarb'

module Mrg
  module Grid
    module Config
      class Subsystem
        include ::Rhubarb::Persisting
        include ::SPQR::Manageable

        qmf_package_name 'mrg.grid.config'
        qmf_class_name 'Subsystem'
        ### Property method declarations
        # property name sstr 

        declare_column :name, :string, :not_null
        declare_index :name
        
        qmf_property :name, :sstr, :index=>true
        ### Schema method declarations
        
        # GetAttrs 
        # * attrs (map/O)
        #   A set of parameter names that the subsystem is interested in
        def GetAttrs()
          # Assign values to output parameters
          attrs ||= {}
          # Return value
          return attrs
        end
        
        expose :GetAttrs do |args|
          args.declare :attrs, :map, :out, {}
        end
        
        # ModifyAttrs 
        # * command (sstr/I)
        #   Valid commands are 'ADD', 'REMOVE', 'UNION', 'INTERSECT', 'DIFF', and 'REPLACE'.
        # * attrs (map/I)
        #   A set of parameter names
        def ModifyAttrs(command,attrs)
          # Print values of input parameters
          log.debug "ModifyAttrs: command => #{command}"
          log.debug "ModifyAttrs: attrs => #{attrs}"
        end
        
        expose :ModifyAttrs do |args|
          args.declare :command, :sstr, :in, {}
          args.declare :attrs, :map, :in, {}
        end
      end
    end
  end
end
