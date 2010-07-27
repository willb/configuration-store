# Parameter:  QMF parameter entity
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
require 'mrg/grid/config/ArcLabel'
require 'mrg/grid/config/ArcUtils'
require 'mrg/grid/config/DataValidating'

require 'set'

module Mrg
  module Grid
    module Config      
      class Parameter
        include ::Rhubarb::Persisting
        include ::SPQR::Manageable
        include DataValidating

        qmf_package_name 'com.redhat.grid.config'
        qmf_class_name 'Parameter'
        ### Property method declarations
        # property name sstr 

        declare_column :name, :string, :not_null
        declare_index_on :name
        
        declare_column :kind, :string, :default, :string
        declare_column :default_val, :string
        declare_column :description, :string
        declare_column :must_change, :boolean, :default, :false
        declare_column :level, :integer
        declare_column :needsRestart, :boolean

        qmf_property :name, :sstr, :index=>true
        qmf_property :kind, :sstr, :desc=>"The type of this parameter"
        qmf_property :default, :lstr, :desc=>"The current default value for this parameter."
        qmf_property :description, :lstr, :desc=>"The description of this parameter."
        qmf_property :must_change, :bool, :desc=>"True if the user must supply a value for this parameter; false otherwise."
        qmf_property :visibility_level, :uint8, :desc=>"The current \"visibility level\" for this parameter."
        qmf_property :requires_restart, :bool, :desc=>"True if the application must be restarted to see a change to this parameter; false otherwise."
        qmf_property :depends, :list, :desc=>"A set of parameter names that this parameter depends on."
        qmf_property :conflicts, :list, :desc=>"A set of parameter names that this parameter conflicts with."
        
        ### Schema method declarations
        
        # setKind
        # * ty (uint8/I)
        def setKind(ty)
          # Print values of input parameters
          log.debug "setType: type => #{ty.inspect}"
          self.kind = ty
        end
        
        expose :setKind do |args|
          args.declare :kind, :sstr, :in, "The type of this parameter."
        end
        
        # default 
        # * default (lstr/O)
        def default
          log.debug "getDefault called on param #{self.inspect}"
          # Assign values to output parameters
          self.default_val ||= ""
          # Return value
          return self.default_val
        end
        
        # setDefault 
        # * default (lstr/I)
        def setDefault(default)
          # Print values of input parameters
          log.debug "setDefault: default => #{default.inspect}"
          DirtyElement.dirty_parameter(self)
          self.default_val = default
        end
        
        expose :setDefault do |args|
          args.declare :default, :lstr, :in, "The new default value for this parameter."
        end
        
        alias db_description description
        alias db_description= description=

        def description()
          log.debug "getDescription called on param #{self.inspect}"
          # Assign values to output parameters
          self.db_description ||= ""
          # Return value
          return self.db_description
        end
        
        # setDescription 
        # * description (lstr/I)
        def setDescription(description)
          # Print values of input parameters
          log.debug "setDescription: description => #{description.inspect}"
          # XXX:  is this necessary?
          # DirtyElement.dirty_parameter(self)
          self.db_description = description
        end
        
        expose :setDescription do |args|
          args.declare :description, :lstr, :in, "A new description of this parameter."
        end
                
        # setMustChange 
        # * mustChange (bool/I)
        def setMustChange(mustChange)
          # Print values of input parameters
          log.debug "setDefaultMustChange: mustChange => #{mustChange.inspect}"
          DirtyElement.dirty_parameter(self)
          self.must_change = mustChange
        end
        
        expose :setMustChange do |args|
          args.declare :mustChange, :bool, :in, "True if the user must supply a value for this parameter; false otherwise."
        end
        
        def visibility_level()
          log.debug "getVisibilityLevel called on param #{self.inspect}"
          self.level ||= 0
          # Return value
          return self.level
        end
        
        # setVisibilityLevel 
        # * level (uint8/I)
        def setVisibilityLevel(level)
          # Print values of input parameters
          log.debug "setVisibilityLevel: level => #{level.inspect}"
          # XXX:  Is this necessary?
          # DirtyElement.dirty_parameter(self)
          self.level = level
        end
        
        expose :setVisibilityLevel do |args|
          args.declare :level, :uint8, :in, "The new \"visibility level\" for this parameter."
        end
        
        # getRequiresRestart 
        # * needsRestart (bool/O)
        def requires_restart
          log.debug "getRequiresRestart called on param #{self.inspect}"
          # Assign values to output parameters
          self.needsRestart ||= false
          # Return value
          return self.needsRestart
        end
        
        expose :getRequiresRestart do |args|
          args.declare :needsRestart, :bool, :out, "True if the application must be restarted to see a change to this parameter; false otherwise."
        end
        
        # setRequiresRestart 
        # * needsRestart (bool/I)
        def setRequiresRestart(needsRestart)
          # Print values of input parameters
          log.debug "setRequiresRestart: needsRestart => #{needsRestart.inspect}"
          DirtyElement.dirty_parameter(self)
          self.needsRestart = needsRestart
        end
        
        expose :setRequiresRestart do |args|
          args.declare :needsRestart, :bool, :in, "True if the application must be restarted to see a change to this parameter; false otherwise."
        end

        # modifyDepends 
        # * command (sstr/I)
        #   Valid commands are 'ADD', 'REMOVE', 'UNION', 'INTERSECT', 'DIFF', and 'REPLACE'.
        # * depends (map/I)
        #   A set of parameter names that this one depends on
        def modifyDepends(command,depends,options)
          # Print values of input parameters
          log.debug "modifyDepends: command => #{command.inspect}"
          log.debug "modifyDepends: depends => #{depends.inspect}"
          
          invalid_depends = Parameter.select_invalid(depends)
          fail(Errors.make(Errors::NONEXISTENT_ENTITY, Errors::PARAMETER), "Invalid parameter names for dependency:  #{invalid_depends.inspect}") if invalid_depends != []
          
          do_validate = false
          new_depends = self.depends
          case command.upcase
          when "ADD" then
            new_depends |= depends
            do_validate = true
          when "REPLACE" then
            new_depends = depends
            do_validate = true
          end

          validate_changes(:new_depends=>new_depends) if do_validate
          
          modify_arcs(command,depends,options,:depends,:depends=,:explain=>"depend upon",:xc=>:x_depends)
          DirtyElement.dirty_parameter(self)
        end
        
        expose :modifyDepends do |args|
          args.declare :command, :sstr, :in, "Valid commands are 'ADD', 'REMOVE', and 'REPLACE'."
          args.declare :depends, :list, :in, "A set of parameter names that this one depends on."
          args.declare :options, :map, :in, "No options are supported at this time."
        end
        
        # modifyConflicts 
        # * command (sstr/I)
        #   Valid commands are 'ADD', 'REMOVE', 'UNION', 'INTERSECT', 'DIFF', and 'REPLACE'.
        # * conflicts (map/I)
        #   A set of parameter names that conflict with this one
        def modifyConflicts(command,conflicts,options)
          # Print values of input parameters
          log.debug "modifyConflicts: command => #{command.inspect}"
          log.debug "modifyConflicts: conflicts => #{conflicts.inspect}"
          
          invalid_conflicts = Parameter.select_invalid(conflicts)
          fail(Errors.make(Errors::NONEXISTENT_ENTITY, Errors::PARAMETER), "Invalid parameter names for conflict:  #{invalid_conflicts.inspect}") if invalid_conflicts != []
          
          do_validate = false
          new_conflicts = self.conflicts
          case command.upcase
          when "ADD" then
            new_conflicts |= conflicts
            do_validate = true
          when "REPLACE" then
            new_conflicts = conflicts
            do_validate = true
          end
          
          validate_changes(:new_conflicts=>new_conflicts) if do_validate
          
          modify_arcs(command,conflicts,options,:conflicts,:conflicts=,:explain=>"conflict with")
          DirtyElement.dirty_parameter(self)
        end
        
        expose :modifyConflicts do |args|
          args.declare :command, :sstr, :in, "Valid commands are 'ADD', 'REMOVE', and 'REPLACE'."
          args.declare :conflicts, :list, :in, "A set of parameter names that this parameter conflicts with."
          args.declare :options, :map, :in, "No options are supported at this time."
        end
        
        def Parameter.s_that_must_change
          self.find_by(:must_change=>true).inject({}) do |acc, param|
            acc[param.name] = param.default_val
            acc
          end
        end
        
        def Parameter.s_for_node(node)
          feature_params = Feature.features_for_node(node).map {|feat| feat.params.keys}.flatten.sort.uniq
          default_group_params = Group.DEFAULT_GROUP.params.keys.sort.uniq
          id_group_params = node.idgroup ? node.idgroup.params.keys.sort.uniq : []
          explicit_group_params = node.send(:db_memberships).map {|grp| grp.params.keys}.flatten.sort.uniq
          
          feature_params | default_group_params | id_group_params | explicit_group_params
        end
        
        def Parameter.dependencies_for_node(node, params_for_node=nil)
          params_for_node ||= Parameter.s_for_node(node)
          params_for_node.map do |param| 
            Parameter.find_first_by_name(param).x_depends
          end.flatten.sort.uniq
        end

        def Parameter.s_for_group(grp)
          feature_params = Feature.features_for_group(grp).map {|feat| feat.params.keys}.flatten.sort.uniq
          explicit_group_params = grp.params.keys
          
          feature_params | explicit_group_params
        end
        
        def Parameter.dependencies_for_group(grp, params_for_group=nil)
          params_for_group ||= Parameter.s_for_group(grp)
          params_for_group.map do |param| 
            Parameter.find_first_by_name(param).x_depends
          end.flatten.sort.uniq
        end
        
        def x_depends(xtra = nil)
          xtra ||= []
          (depends | xtra).inject([]) do |acc,prm|
            acc << prm
            acc |= Parameter.find_first_by_name(prm).x_depends
            acc
          end
        end

        def depends
          find_arcs(ParameterArc,ArcLabel.depends_on('param')) {|pa| pa.dest.name }
        end
        
        def conflicts
          find_arcs(ParameterArc,ArcLabel.conflicts_with('param')) {|pa| pa.dest.name }
        end
        
        def x_depends(xtra=[])
          raw_depends = find_arcs(ParameterArc,ArcLabel.depends_on('param')) {|pa| pa.dest }
          raw_depends |= xtra.map {|pn| Parameter.find_first_by_name(pn)}.compact
          result = Set.new
          raw_depends.each do |rd|
            result << rd.name
            rd.x_depends.each do |xd|
              # nb:  x_depends returns an array of names, not params
              result << xd
            end
          end
          
          result.to_a
        end
        
        def depended_on_by
          ParameterArc.find_by(:dest=>self, :label=>ArcLabel.depends_on('param')).map {|pa| pa.source}
        end
        
        def x_depended_on_by
          raw_dependents = depended_on_by
          result = Set[*raw_dependents.map {|rd| rd.name}]
          raw_dependents.each do |rd|
            rd.x_depended_on_by.each do |xdpt|
              result << xdpt
            end
          end
          
          result.to_a
        end
        
        private
        
        include ArcUtils
        
        def validate_changes(options=nil)
          options ||= {}
          {:new_depends=>Proc.new {self.depends},
           :new_conflicts=>Proc.new {self.conflicts}}.each do |option, dproc| 
            options[option] ||= dproc.call
          end
          
          error_code = Errors.make(Errors::INVALID_RELATIONSHIP, Errors::PARAMETER)
          intersection = options[:new_depends] & options[:new_conflicts]
          
          fail(error_code, "Param #{name} cannot both immediately depend on and immediately conflict with #{intersection.inspect}") unless intersection == []
          
          intersection = x_depends(options[:new_depends]) & options[:new_conflicts]
          fail(error_code, "Param #{name} cannot both transitively depend on and immediately conflict with #{intersection.inspect}") unless intersection == []
          
          intersection = x_depended_on_by & options[:new_conflicts]
          fail(error_code, "Param #{name} cannot conflict with parameters that depend on it: #{intersection.inspect}") unless intersection == []
        end
        
        def depends=(deps)
          set_arcs(ParameterArc, ArcLabel.depends_on('param'), deps, :find_first_by_name)
        end
        
        def conflicts=(conflicts)
          set_arcs(ParameterArc, ArcLabel.conflicts_with('param'), conflicts, :find_first_by_name)
        end
      end
    
      class ParameterArc
        include ::Rhubarb::Persisting
        declare_column :source, :integer, :not_null, references(Parameter, :on_delete=>:cascade)
        declare_column :dest, :integer, :not_null, references(Parameter, :on_delete=>:cascade)
        declare_column :label, :integer, :not_null, references(ArcLabel)
      end
    end
  end
end
