#!/usr/bin/env ruby

# activate:  wallaby shell command to activate current changes to the configuration
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

module Mrg
  module Grid
    module Config
      module Shell
        class Activate
          def initialize(storeclient, name, op=:activate)

            @op = op
            @store = storeclient
            @name = name

            @options = {}
            @oparser = OptionParser.new do |opts|
              
              opname = "activate"
              
              opts.banner = "Usage:  wallaby #{opname}\nActivates pending changes to the pool configuration."
                
              opts.on("-h", "--help", "displays this message") do
                puts @oparser
                exit
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
            explain = @store.activateConfig
            if explain != {}
              puts "Failed to activate configuration; please correct the following errors."
              explain.each do |node, node_explain|
                puts "#{node}:"
                node_explain.each do |reason, ls|
                  puts "  #{reason}: #{ls.inspect}"
                end
              end
              return 1
            end
            0
          end
          
        end

        Mrg::Grid::Config::Shell::COMMANDS['activate'] = Activate
        
      end
    end
  end
end