# graph.rb:  directed and undirected graphs with labeled edges; 
# also, related utilities
#
# Copyright (c) 2010 Red Hat, Inc.
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

require 'set'

module Mrg
  module Grid
    module Util
      class Graph
        attr_reader :nodes, :edges, :labels, :directed

        module LabeledGraph
          def actually_add_edge(from, to, label="")
            ensure_nodes(from, to)
            @labels << label
            edges[from] << [label, to]
          end
        end

        module UnlabeledGraph
          def actually_add_edge(from, to, label)
            ensure_nodes(from, to)
            edges[from] << ["", to]
          end
        end

        def initialize(options = nil)
          options ||= {}
          @labeled_edges = !options[:ignore_labels]
          @directed = !options[:undirected]

          if @labeled_edges
            @labels = []
            class << self
              include LabeledGraph
            end
          else
            class << self
              include UnlabeledGraph
            end
          end

          @nodes = Set.new
          @edges = Hash.new {|h,k| h[k] = Set.new; h[k]}
          @add_edge_callbacks = []

          unless self.directed
            @add_edge_callbacks << Proc.new {|from,to,label| actually_add_edge(to,from,label)}
          end
        end

        def labeled_edges_from(from, *labels)
          edges[from].select {|l,n| labels.size == 0 || labels.include?(l)}
        end
        
        def edges_from(from, *labels)
          result = labeled_edges_from(from, labels)

          result.map {|l,n| n}.uniq
        end

        def add_edge(from, to, label="")
          actually_add_edge(from, to, label)
          @add_edge_callbacks.each do |c|
            c.call(from,to,label)
          end
        end

        private

        def ensure_nodes(*ns)
          ns.each {|n| nodes << n}
        end
      end

      class GraphInvariantViolation < RuntimeError ; end

      module TopologicalSorter
        def self.sort(graph)
          stack = []

          post_visit_callback = Proc.new {|node, dfs| stack << node}
          edge_callback = Proc.new do |from, to, label, dfs|
            if dfs.discovered[to] && !dfs.processed[to]
              raise GraphInvariantViolation.new("graph #{graph} is not a DAG (back edge from #{from} --> #{to})")
            end
          end

          dfs = DFS.new(graph, nil, post_visit_callback, edge_callback)

          graph.nodes.each do |node|
            dfs.dfs(node, false) unless dfs.discovered[node]
          end

          stack
        end
      end

      class DFS
        class Done < Exception
        end

        attr_reader :time, :entry_time, :discovered, :processed, :parent
        attr_accessor :finished

        def initialize(graph, pre_visit_callback=nil, post_visit_callback=nil, edge_callback=nil)
          @graph = graph
          @pre_visit_callbacks ||= []
          @pre_visit_callbacks << pre_visit_callback if pre_visit_callback
          @post_visit_callbacks ||= []
          @post_visit_callbacks << post_visit_callback if post_visit_callback
          @edge_callbacks ||= []
          @edge_callbacks << edge_callback if edge_callback
          reset_self
        end

        def dfs(node, reset=true)
          if reset
            reset_self
          end
          
          begin
            do_dfs(node)
          rescue Done
            return
          end
        end

        private

        def reset_self
          @time = 0
          @discovered = {}
          @processed = {}
          @entry_time = {}
          @exit_time = {}
          @finished = false
          @parent = {}
        end

        def tick
          @time = @time + 1
        end

        def do_dfs(node)
          raise Done.new if @finished
          
          @discovered[node] = true
          tick
          @entry_time[node] = time
          
          @pre_visit_callbacks.each {|cb| cb.call(node, self)}

          outbound_edges = @graph.labeled_edges_from(node)
          
          outbound_edges.each do |label, to_node|
            if !@discovered[to_node]
              @parent[to_node] = node
              @edge_callbacks.each {|ec| ec.call(node, to_node, label, self) }
              do_dfs(to_node)
            elsif @processed[to_node] || @graph.directed
              @edge_callbacks.each {|ec| ec.call(node, to_node, label, self) }
              raise Done.new if @finished
            end
          end

          @post_visit_callbacks.each {|cb| cb.call(node, self)}

          tick
          @exit_time[node] = time

          @processed[node] = true
        end
      end

      class Floyd
        MAX = ((1 << (0.size * 8 - 4)) - 1)
        
        attr_reader :xc
        
        def initialize(graph)
          @nodes = graph.nodes.to_a
          @node_positions = {}
          @nodes.each_with_index {|k,v| @node_positions[k] = v}

          @path_via = @nodes.map {|n| [nil] * @nodes.size}
          @path_sizes = @nodes.map {|n| [MAX] * @nodes.size}
          @edge_kinds = @nodes.map {|n| @nodes.map{|n2| []}}
          
          @xc = Hash.new {|h,k| h[k] = Set.new}
          
          graph.edges.each do |from, edges|
            edges.each do |label, to|
              from_idx = @node_positions[from]
              to_idx = @node_positions[to]
              @path_sizes[from_idx][to_idx] = 1
              @edge_kinds[from_idx][to_idx] << label
              @xc[from] << to
            end
          end

          @nodes.size.times do |k|
            @nodes.size.times do |i|
              @nodes.size.times do |j|
                tmp = @path_sizes[i][k]+@path_sizes[k][j]
                if tmp < @path_sizes[i][j]
                  @path_sizes[i][j] = tmp
                  @path_via[i][j] = [@edge_kinds[k][j][0], @nodes[k]]
                  @xc[@nodes[i]] << @nodes[j]
                end
              end
            end
          end     
        end

        def shortest_path(from_node, to_node)
          from = @node_positions[from_node]
          to = @node_positions[to_node]
          
          return nil if @path_sizes[from][to] == MAX
          via = @path_via[from][to]
          edge_kind = @edge_kinds[from][to][0] || "-->"
          edge_kind = "-->" if edge_kind.size == 0
          
          via_edge = ["#{from_node}", "#{edge_kind}", "#{to_node}"]
          return [via_edge] unless via
          return [shortest_path(from_node, via[1])[0], via_edge]
        end
      end
    end
  end
end
