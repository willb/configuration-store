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
          params
        end
        
        expose :GetParams do |args|
          args.declare :params, :list, :out, {}
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
          
          invalid_params = Parameter.select_invalid(params)
          fail(42, "Invalid parameters for observation by subsystem #{self.name}:  #{invalid_params.inspect}") if invalid_params != []
          
          modify_arcs(command,params,options,:params,:params=,:explain=>"observe the param")
          DirtyElement.dirty_subsystem(self)
        end
        
        expose :ModifyParams do |args|
          args.declare :command, :sstr, :in, {}
          args.declare :params, :list, :in, {}
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
