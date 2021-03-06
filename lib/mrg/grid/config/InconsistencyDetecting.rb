# InconsistencyDetecting.rb:  mixin for detecting problems on relations between features or parameters
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

require 'mrg/grid/util/graph'
require 'mrg/grid/config/errors'

module Mrg
  module Grid
    module Config
      module InconsistencyDetecting
        def c_basename
          self.class.name.split("::").pop
        end
        
        def error_kind
          Errors.const_get(c_basename.upcase)
        end
        
        def what_am_i
          c_basename.downcase
        end
        
        def self_arc_class
          Mrg::Grid::Config::const_get("#{c_basename}Arc")
        end
        
        def id_valid_commands
          %w{ADD REPLACE REMOVE UNION INTERSECT DIFF}
        end
        
        def id_callbacks
          []
        end
        
        # a human-readable name for this class must be what_am_i
        # the class containing relationships between instances of this class must be given in self_arc_class
        # collection must be in id_labels.keys
        # a mapping from relationships to arc label messages must be in id_labels
        # command must be in id_valid_commands
        # the constant for the type of entity self is must be given in error_kind
        
        # ls is the argument to the API call
        def detect_inconsistencies(collection, command, ls)
          return if $wallaby_skip_inconsistency_detection
          command = command.upcase
          gerund = command.downcase.sub(/([e]|)$/, "ing")
          arcs = {}

          ls = Set[*ls]

          raise "bogus collection #{collection.inspect}" unless id_labels.keys.include?(collection)
          raise "bogus command #{command.inspect}" unless id_valid_commands.include?(command)

          id_labels.each do |arcs_key,arclabel_msg|
            tmp = self_arc_class.find_by_label(ArcLabel.send(arclabel_msg, "#{what_am_i}").row_id)

            arcs[arcs_key] = tmp.inject(Hash.new {|h,k| h[k] = Set.new}) do |acc, arc|
              acc[arc.source.name] << arc.dest.name
              acc
            end
          end

          preposition = "to"

          case command
          when "ADD" then
            arcs[collection][name] |= ls
            preposition = "to"
          when "REPLACE" then
            arcs[collection][name] = ls
            preposition = "with"
          when "REMOVE" then
            arcs[collection][name] -= ls
            preposition = "from"
          end

          # build the inclusion-dependency graph
          g = ::Mrg::Grid::Util::Graph.new

          id_relations_for_graph.each do |key, label|
            arcs[key].each do |source, dests|
              dests.each do |dest|
                log.debug "InconsistencyDetecting:  adding a #{label} edge from #{source} to #{dest}"
                g.add_edge(source, dest, label)
              end
            end
          end

          begin
            ::Mrg::Grid::Util::TopologicalSorter.sort(g)
          rescue ::Mrg::Grid::Util::Graph::InvariantViolation
            fail(Errors.make(error_kind, Errors::INVALID_RELATIONSHIP), "#{gerund} #{ls.inspect} to the #{collection} set of #{what_am_i} #{name} would introduce a circular inclusion or dependency relationship")
          end

          log.debug "validating changes to #{self.class.name}:#{self.name}; doing XC over a #{g.nodes.size}-node graph"
          floyd = ::Mrg::Grid::Util::Graph::DagTransitiveClosure.new(g)

          # keep track of all failures, to present a comprehensive error message at the end
          failures = []

          floyd.xc.each do |source, dests|
            conflict_range = dests.inject(arcs[:conflicts][source]) do |acc, dest|
              acc |= arcs[:conflicts][dest]
              acc
            end

            intersection = conflict_range & (dests | [source])

            if intersection.size > 0
              intersection.each do |dest|
                failures << "\t * this change would break #{source}, which transitively #{id_requires_msg} #{name} and cannot carry #{intersection.to_a.inspect} as conflicts"
              end
            end
          end

          id_callbacks.each do |cb|
            cb.call(g, floyd, failures)
          end

          if failures.size > 0
            fail(Errors.make(error_kind, Errors::INVALID_RELATIONSHIP), "#{gerund} the #{collection} set #{preposition} #{ls.to_a.inspect} of #{what_am_i} #{name} would introduce the following inconsistenc#{failures.size > 1 ? "ies" : "y"}:\n#{failures.join('\n')}")
          end
        end
      end
    end
  end
end
