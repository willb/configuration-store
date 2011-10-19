# Subsystem:  QMF subsystem entity
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

require 'mrg/grid/config'
require 'mrg/grid/config/MethodUtils'

module Mrg
  module Grid
    module Config
      class Subsystem
        include ::Rhubarb::Persisting
        include ::SPQR::Manageable
        include DataValidating
        include MethodUtils

        qmf_package_name 'com.redhat.grid.config'
        qmf_class_name 'Subsystem'
        ### Property method declarations
        # property name sstr 

        declare_column :name, :text, :not_null
        declare_index_on :name
        
        qmf_property :name, :sstr, :index=>true
        qmf_property :params, :list, :desc=>"A list representing the set of parameter names that this subsystem is interested in."
        ### Schema method declarations

        # modifyParams 
        # * command (sstr/I)
        #   Valid commands are 'ADD', 'REMOVE', 'UNION', 'INTERSECT', 'DIFF', and 'REPLACE'.
        # * params (map/I)
        #   A set of parameter names
        def modifyParams(command,params,options={})
          # Print values of input parameters
          log.debug "modifyParams: command => #{command.inspect}"
          log.debug "modifyParams: params => #{params.inspect}"
          log.debug "modifyParams: options => #{options.inspect}"
          
          invalid_params = Parameter.select_invalid(params)
          fail(Errors.make(Errors::NONEXISTENT_ENTITY, Errors::PARAMETER), "Invalid parameters for observation by subsystem #{self.name}:  #{invalid_params.inspect}") if invalid_params != []
          
          modify_arcs(command,params,options,:params,:params=,:explain=>"observe the param")
          DirtyElement.dirty_subsystem(self)
        end
        
        expose :modifyParams do |args|
          args.declare :command, :sstr, :in, "Valid commands are 'ADD', 'REMOVE', and 'REPLACE'."
          args.declare :params, :list, :in, "A list representing the set of parameter names that this subsystem should be interested in (for ADD and REPLACE) or should not be interested in (for REMOVE)."
          args.declare :options, :map, :in, "No options are supported at this time."
        end
        
        def params
          find_arcs(SubsystemParams,ArcLabel.implication('parameter')) {|a| a.dest.name }
        end
        
        
        def self.s_for_param(param)
          p = Parameter.find_first_by_name(param)
          SubsystemParams.find_by(:dest=>p, :label=>ArcLabel.implication('parameter')).map {|sp| sp.source}
        end
          
        private
        include ArcUtils
        
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
