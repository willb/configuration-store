# graph.rb:  directed and undirected graphs, with (optionally-)labeled edges
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

# XXX:  make this a labeled graph by default

module Mrg
  module Grid
    module Util
      class Graph
        module LabeledGraph
          def _add_edge(from, to, label="")
            ensure_nodes(from, to)
            @labels << label
            edges[from] << [label, to]
          end

          def labeled_edges_from(from, label)
            edges[from]select {|l,n| l == label}.map {|l,n| n}
          end
        
          def edges_from(from)
            edges[from].map {|l,n| n}.uniq
          end
        end

        module UnlabeledGraph
          def _add_edge(from, to, label=nil)
            ensure_nodes(from, to)
            edges[from] << to
          end
        end
        
        attr_reader :nodes, :edges, :labels

        def initialize(directed=true, labeled_edges=false)

          @labeled_edges = labeled_edges

          if labeled_edges
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
          @edges = Hash.new {|h,k| h[k] = Set.new}
          @add_edge_callbacks = []

          unless directed
            @add_edge_callbacks << Proc.new {|from,to,label| _add_edge(to,from,label)}
          end
        end

        def edges_from(from)
          edges[from].dup
        end

        def add_edge(from, to, label="")
          _add_edge(from, to, label)
          @add_edge_callbacks.each do |c|
            c.call(from,to,label)
          end
        end

        private
        def ensure_nodes(*ns)
          ns.each {|n| nodes << n}
        end
      end

      class DFS
        class Done < Exception
        end

        attr_reader :time
        attr_accessor :finished

        def initialize(graph, pre_visit_callback=nil, post_visit_callback=nil, edge_callback=nil)
          @graph = graph
          @pre_visit_callbacks ||= []
          @pre_visit_callbacks << pre_visit_callback if pre_visit_callback
          @post_visit_callbacks ||= []
          @post_visit_callbacks << post_visit_callback if post_visit_callback
          @edge_callbacks ||= []
          @edge_callbacks << edge_callback if edge_callback
        end

        def dfs(node)
          @time = 0
          @discovered = {}
          @processed = {}
          @entry_time = {}
          @finished = false
          @parent = {}
          
          begin
            do_dfs(node)
          rescue Done
            return
          end
        end
        
        private
        def do_dfs(node)
          raise Done.new if finished

          @discovered[node] = true
          @time = @time + 1
          @entry_time[node] = time

          pre_visit_callbacks.each do {|cb| cb.call(node, self)}



          post_visit_callbacks.each do {|cb| cb.call(node, self)}

          
        end
      end
    end
  end
end
