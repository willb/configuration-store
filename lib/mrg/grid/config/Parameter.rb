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
        ### Schema method declarations
        
        # getType 
        # * type (uint8/O)
        def getType()
          log.debug "getType called on param #{self.inspect}"
          # Assign values to output parameters
          return kind
        end
        
        expose :getType do |args|
          args.declare :type, :sstr, :out, "An int corresponding to the type of this parameter."
        end
        
        # setType 
        # * ty (uint8/I)
        def setType(type)
          # Print values of input parameters
          log.debug "setType: type => #{type.inspect}"
          self.kind = type
        end
        
        expose :setType do |args|
          args.declare :type, :sstr, :in, "An int corresponding to the type of this parameter."
        end
        
        # getDefault 
        # * default (lstr/O)
        def getDefault()
          log.debug "getDefault called on param #{self.inspect}"
          # Assign values to output parameters
          self.default_val ||= ""
          # Return value
          return self.default_val
        end
        
        expose :getDefault do |args|
          args.declare :default, :lstr, :out, "The current default value for this parameter."
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
        
        # getDescription 
        # * description (lstr/O)
        def getDescription()
          log.debug "getDescription called on param #{self.inspect}"
          # Assign values to output parameters
          self.description ||= ""
          # Return value
          return self.description
        end
        
        expose :getDescription do |args|
          args.declare :description, :lstr, :out, "The description of this parameter."
        end
        
        # setDescription 
        # * description (lstr/I)
        def setDescription(description)
          # Print values of input parameters
          log.debug "setDescription: description => #{description.inspect}"
          # XXX:  is this necessary?
          # DirtyElement.dirty_parameter(self)
          self.description = description
        end
        
        expose :setDescription do |args|
          args.declare :description, :lstr, :in, "A new description of this parameter."
        end
        
        # getDefaultMustChange 
        # * mustChange (bool/O)
        def getDefaultMustChange()
          log.debug "getDefaultMustChange called on param #{self.inspect}"
          return self.must_change
        end
        
        expose :getDefaultMustChange do |args|
          args.declare :mustChange, :bool, :out, "True if the user must supply a value for this parameter; false otherwise."
        end
        
        # setDefaultMustChange 
        # * mustChange (bool/I)
        def setDefaultMustChange(mustChange)
          # Print values of input parameters
          log.debug "setDefaultMustChange: mustChange => #{mustChange.inspect}"
          DirtyElement.dirty_parameter(self)
          self.must_change = mustChange
        end
        
        expose :setDefaultMustChange do |args|
          args.declare :mustChange, :bool, :in, "True if the user must supply a value for this parameter; false otherwise."
        end
        
        # getVisibilityLevel 
        # * level (uint8/O)
        def getVisibilityLevel()
          log.debug "getVisibilityLevel called on param #{self.inspect}"
          self.level ||= 0
          # Return value
          return self.level
        end
        
        expose :getVisibilityLevel do |args|
          args.declare :level, :uint8, :out, "The current \"visibility level\" for this parameter."
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
        def getRequiresRestart()
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
        
        # getDepends 
        # * depends (map/O)
        #   A set of parameter names that this one depends on
        def getDepends()
          log.debug "getDepends called on param #{self.inspect}"
          depends
        end
        
        expose :getDepends do |args|
          args.declare :depends, :list, :out, "A set of parameter names that this parameter depends on."
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
          
          modify_arcs(command,depends,options,:depends,:depends=,:explain=>"depend upon",:xc=>:x_depends)
          DirtyElement.dirty_parameter(self)
        end
        
        expose :modifyDepends do |args|
          args.declare :command, :sstr, :in, "Valid commands are 'ADD', 'REMOVE', and 'REPLACE'."
          args.declare :depends, :list, :in, "A set of parameter names that this one depends on."
          args.declare :options, :map, :in, "No options are supported at this time."
        end
        
        # getConflicts 
        # * conflicts (map/O)
        #   A set of parameter names that conflict with the parameter
        def getConflicts()
          log.debug "getConflicts called on param #{self.inspect}"
          conflicts
        end
        
        expose :getConflicts do |args|
          args.declare :conflicts, :list, :out, "A set of parameter names that this parameter conflicts with."
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
          default_group_params = Group.DEFAULT_GROUP.getParams.keys.sort.uniq
          id_group_params = node.idgroup ? node.idgroup.getParams.keys.sort.uniq : []
          explicit_group_params = node.send(:memberships).map {|grp| grp.getParams.keys}.flatten.sort.uniq
          
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
          explicit_group_params = grp.getParams.keys
          
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
        
        private
        
        include ArcUtils
        
        def depends
          find_arcs(ParameterArc,ArcLabel.depends_on('param')) {|pa| pa.dest.name }
        end
        
        def conflicts
          find_arcs(ParameterArc,ArcLabel.conflicts_with('param')) {|pa| pa.dest.name }
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
