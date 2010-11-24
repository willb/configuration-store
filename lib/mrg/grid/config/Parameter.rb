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
require 'mrg/grid/config/InconsistencyDetecting'

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
        
        # We're overriding find_first_by_name to be case-insensitive
        declare_query :_find_first_by_name_ci, "length(name) = length(?1) and upper(name) = upper(?1) ORDER BY row_id"

        def self.find_first_by_name(name)
          return _find_first_by_name_ci(name)[0]
        end
        
        def eql?(other)
          return self.class == other.class && self.row_id == other.row_id
        end
        
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
          log.warn "param #{self.name} is a must_change parameter; its default value is meaningless by definition" if self.must_change
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
          
          if self.must_change
            log.warn "ignoring attempt to set the default value of must_change param #{self.name}"
            return
          end
          
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
          
          options ||= {}          
          skip_validation = options["skip_validation"] && %w{true yes}.include?(options["skip_validation"].downcase)
          
          
          unless skip_validation
            detect_inconsistencies(:depends, command, depends)
            validate_consequences(:depends, command, depends)
          end
          
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
          
          options ||= {}          
          skip_validation = options["skip_validation"] && %w{true yes}.include?(options["skip_validation"].downcase)
          
          unless skip_validation
            detect_inconsistencies(:conflicts, command, conflicts)
            validate_consequences(:conflicts, command, conflicts)
          end
          
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
                
        private
        
        include ArcUtils
        
        def what_am_i
          "param"
        end
        
        def id_labels
          {:conflicts=>:conflicts_with, :depends=>:depends_on}
        end
        
        def id_relations_for_graph
          {:depends=>"depends on"}
        end
        
        def id_require_msg
          "depend on"
        end

        def id_requires_msg
          "depends on"
        end
        include InconsistencyDetecting
        
        
        # XXX:  refactor to eliminate code duplication
        def validate_consequences(collection, command, ls)
          ls ||= []
          result = []

          return result if $wallaby_skip_inconsistency_detection

          pv_graph = ::Mrg::Grid::Util::Graph.new
          arcs = {}
          
          parameters_of_interest = Set.new
          
          arcs[:conflicts] = Hash.new {|h,k| h[k] = Set.new}
          arcs[:depends] = Hash.new {|h,k| h[k] = Set.new}

          # NB:  since this graph has heterogeneous nodes, we don't use names -- we use references to actual objects
          FeatureArc.find_by(:label=>ArcLabel.depends_on('feature')).each do |fa|
            pv_graph.add_edge(fa.source, fa.dest, "depends on")
          end

          FeatureArc.find_by(:label=>ArcLabel.inclusion('feature')).each do |fa|
            pv_graph.add_edge(fa.source, fa.dest, "includes")
          end

          ParameterArc.find_by(:label=>ArcLabel.depends_on('param')).each do |pa|
            arcs[:depends][pa.source] << pa.dest
            parameters_of_interest << pa.source.row_id
            parameters_of_interest << pa.dest.row_id
          end

          ParameterArc.find_by(:label=>ArcLabel.conflicts_with('param')).each do |pa|
            arcs[:conflicts][pa.source] << pa.dest.name
            parameters_of_interest << pa.source.row_id
            parameters_of_interest << pa.dest.row_id
          end

          case command.upcase
          when "ADD" then
            arcs[collection][self] += ls.map {|pn| Parameter.find_first_by_name(pn)}
          when "REMOVE" then
            arcs[collection][self] -= ls.map {|pn| Parameter.find_first_by_name(pn)}
          when "REPLACE" then
            arcs[collection][self] -= ls.map {|pn| Parameter.find_first_by_name(pn)}
          end

          arcs[:depends].each do |source, dests|
            dests.each do |dest|
              pv_graph.add_edge(source, dest, "param dependency")
            end
          end

          FeatureParams.find_all do |fp|
            pv_graph.add_edge(fp.feature, fp.param, "sets param value") if parameters_of_interest.include?(fp.param)
          end

          log.debug "validate_consequences:  checking changes to #{self.class.name}:#{self.name}; doing XC over a #{pv_graph.nodes.size}-node graph"
          feature_param_xc = ::Mrg::Grid::Util::Graph::DagTransitiveClosure.new(pv_graph)

          feature_param_xc.xc.each do |source, dests|
            # source is the feature we're looking at; dests is the set of parameters set 
            # on this feature and all of its included/dependent features.  For each feature,
            # we want to make sure that the set of parameters conflicted with by dests does 
            # not intersect dests.

            conflict_range = dests.inject(Set.new) {|acc,dest| acc |= arcs[:conflicts][dest]}.to_a

            intersection = dests & conflict_range

            result << "\t * Feature #{source.name} sets the following parameters that would transitively conflict with other parameters it sets:  #{intersection.inspect}" if intersection.size > 0
          end

          fail(Errors::make(Errors::PARAMETER, Errors::FEATURE, Errors::INVALID_RELATIONSHIP), "Modifying the #{collection} set of #{self.name} would affect the following features:\n" + result.join("\n")) if result.size > 0
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
