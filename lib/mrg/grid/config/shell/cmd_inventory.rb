# inventory:  wallaby node inventory command
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

require 'ostruct'

module Mrg
  module Grid
    module Config
      module Shell
        class Inventory < Command
          SORTKEYS = %w{name checkin}
          NODEKINDS = %w{provisioned unprovisioned}
          
          def format_time(t)
            return "never" if t == 0
            Time.at(t/1000000,t%1000000).to_s
          end
          
          def self.opname
            "inventory"
          end
          
          def self.description
            "Lists (a subset of) wallaby-managed nodes."
          end
          
          def init_option_parser
            
            OptionParser.new do |opts|
              @sortby = 'name'
              @constraint = nil
              
              opname = "inventory"
              
              opts.banner = "Usage:  wallaby #{opname} [options]\nInventory of nodes that are managed by wallaby."
                
              opts.on("-h", "--help", "displays this message") do
                puts @oparser
                exit
              end
              
              opts.on("-s", "--sort KEY", SORTKEYS, "sort by key", "   (#{SORTKEYS.join(", ")})") do |sort|
                @sortby = sort.downcase
              end

              opts.on("-o", "--only KIND", NODEKINDS, "show only KIND nodes", "   (#{NODEKINDS.join(", ")})") do |nkind|
                @constraint = "provisioned == #{nkind == 'provisioned'}"
              end
              
              opts.on("-c", "--constraint EXPR", "show only nodes for which EXPR is true") do |expr|
                @constraint = expr
              end
            end
          end

          def act
            nodes = store.console.objects(:class=>"Node")

            ::Fixnum.class_eval do
              def hour_ago
                tm = Time.now.utc - (60 * 60 * self)
                (tm.tv_sec * 1000000) + tm.tv_usec
              end
              
              alias :hours_ago :hour_ago
              
              def is_never
                self == 0
              end
            end

            nodes = nodes.select {|node| @constraint == nil || safe_instance_eval(node,@constraint)}
            node_structs = nodes.map do |node|
              n = OpenStruct.new
              n.name = node.name
              n.provisioned = node.provisioned
              n.checkin = node.last_checkin
              n
            end

            if node_structs.size == 0
              puts "No matching nodes configured."
              return 1
            end

            printf("%25.25s %15.15s %40.40s\n", "node name", "is provisioned?", "last checkin")
            printf("%25.25s %15.15s %40.40s\n", "---------", "---------------", "------------")

            node_structs.sort_by {|node| node.send(@sortby)}.each do |node|
              printf("%25.25s %15.15s %40.40s\n", node.name, node.provisioned ? "provisioned" : "unprovisioned", format_time(node.checkin))
            end
            return 0
          end
          
          private
          def safe_instance_eval(obj, str)
            Thread.start {
              $SAFE=4
              obj.instance_eval str
            }.value
          end
          
        end
      end
    end
  end
end
