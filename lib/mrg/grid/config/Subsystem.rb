require 'mrg/grid/config'

module Mrg
  module Grid
    module Config
      class Subsystem
        include ::Rhubarb::Persisting
        include ::SPQR::Manageable
        include DataValidating

        qmf_package_name 'mrg.grid.config'
        qmf_class_name 'Subsystem'
        ### Property method declarations
        # property name sstr 

        declare_column :name, :string, :not_null
        declare_index_on :name
        
        qmf_property :name, :sstr, :index=>true
        ### Schema method declarations
        
        # GetParams 
        # * params (map/O)
        #   A set of parameter names that the subsystem is interested in
        def GetParams()
          return FakeSet[*params]
        end
        
        expose :GetParams do |args|
          args.declare :params, :map, :out, {}
        end
        
        # ModifyParams 
        # * command (sstr/I)
        #   Valid commands are 'ADD', 'REMOVE', 'UNION', 'INTERSECT', 'DIFF', and 'REPLACE'.
        # * params (map/I)
        #   A set of parameter names
        def ModifyParams(command,params,options={})
          # Print values of input parameters
          log.debug "ModifyParams: command => #{command.inspect}"
          log.debug "ModifyParams: params => #{params.inspect}"
          log.debug "ModifyParams: options => #{options.inspect}"
          
          modify_arcs(command,params.keys,options,:params,:params=,:explain=>"observe the param")
          DirtyElement.dirty_subsystem(self)
        end
        
        expose :ModifyParams do |args|
          args.declare :command, :sstr, :in, {}
          args.declare :params, :map, :in, {}
          args.declare :options, :map, :in, {}
        end
        
        private
        include ArcUtils
        
        def params
          find_arcs(SubsystemParams,ArcLabel.implication('parameter')) {|a| a.dest.name }
        end
        
        def params=(deps)
          set_arcs(SubsystemParams, ArcLabel.implication('parameter'), deps, :find_first_by_name, :klass=>Parameter)
        end
        
      end

      class SubsystemParams
        include ::Rhubarb::Persisting
        declare_column :source, :integer, :not_null, references(Subsystem, :on_delete=>:cascade)
        declare_column :dest, :integer, :not_null, references(Parameter, :on_delete=>:cascade)
        declare_column :label, :integer, :not_null, references(ArcLabel)
      end

    end
  end
end
