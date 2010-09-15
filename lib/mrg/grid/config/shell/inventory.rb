#!/usr/bin/env ruby

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
        class Inventory
          SORTKEYS = %w{name checkin}
          NODEKINDS = %w{provisioned unprovisioned}
          
          def format_time(t)
            return "never" if t == 0
            Time.at(t/1000000,t%1000000).to_s
          end
          
          def initialize(storeclient, name, op=:inventory)

            @sortby = 'name'
            @allnodes = true
            @nodekind = ''

            @op = op
            @store = storeclient
            @name = name

            @options = {}
            @oparser = OptionParser.new do |opts|
              
              opname = "inventory"
              
              opts.banner = "Usage:  wallaby #{opname} [options]\nInventory of nodes that are managed by wallaby."
                
              opts.on("-h", "--help", "displays this message") do
                puts @oparser
                exit
              end
              
              opts.on("-s", "--sort KEY", SORTKEYS, "sort by key", "   (#{SORTKEYS.join(", ")})") do |sort|
                @sortby = sort.downcase
              end

              opts.on("-a", "--all", "show all nodes (default)") do
                @allnodes = true
              end

              opts.on("-o", "--only KIND", NODEKINDS, "show only KIND nodes", "   (#{NODEKINDS.join(", ")})") do |nkind|
                @allnodes = false
                @nodekind = nkind.downcase
              end
              
            end

          end
          
          def main(args)
            begin
              @oparser.parse!(args)
            rescue OptionParser::InvalidOption
              puts @oparser
              return 1
            rescue OptionParser::InvalidArgument => ia
              puts ia
              puts @oparser
              return 1
            end
            
            act
          end
          
          def act(kwargs=nil)
            nodes = @store.console.objects(:class=>"Node")

            nodes = nodes.map do |node|
              n = OpenStruct.new
              n.name = node.name
              n.provisioned = node.provisioned
              n.checkin = node.last_checkin
              ((@allnodes || ((@nodekind == "provisioned") == n.provisioned)) && n) || nil
            end.compact

            if nodes.size == 0
              puts "No nodes configured."
              return 1
            end

            printf("%25.25s %15.15s %40.40s\n", "node name", "is provisioned?", "last checkin")
            printf("%25.25s %15.15s %40.40s\n", "---------", "---------------", "------------")

            nodes.sort_by {|node| node.send(@sortby)}.each do |node|
              printf("%25.25s %15.15s %40.40s\n", node.name, node.provisioned ? "provisioned" : "unprovisioned", format_time(node.checkin))
            end
            return 0
          end
        end

        Mrg::Grid::Config::Shell::COMMANDS['inventory'] = Inventory
        
      end
    end
  end
end
