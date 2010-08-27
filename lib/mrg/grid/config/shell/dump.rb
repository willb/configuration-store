#!/usr/bin/env ruby

# dump:  dump a snapshot to a file
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
        module DumpSupport
          class LegacyInterface
            def command
              "dump"
            end
            
            def banner
              "Usage: wallaby-dump FILE"
            end
            
            def collect_specific_options(opts, specific_options)

            end
            
            include ::Mrg::Grid::Config::Shell::GenericLegacyInterface
          end
        end
        
        class Dump
          def initialize(storeclient, name, op=:dump)

            @op = op
            @store = storeclient
            @name = name

            @options = {}
            @oparser = OptionParser.new do |opts|
              
              opname = "dump"
              
              opts.banner = "Usage:  wallaby #{opname} SNAPFILE\nDumps a wallaby snapshot to SNAPFILE."
                
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
              return
            rescue OptionParser::InvalidArgument => ia
              puts ia
              puts @oparser
              return
            end
            
            if args.size > 1
              puts "wallaby dump: You must specify only one output file (or \"--\")."
              puts op
              exit
            end

            @outfile = (args[0] || "--")

            act
          end
          
          def act(kwargs=nil)
            s = Mrg::Grid::SerializedConfigs::ConfigSerializer.new(@store, @store.is_a?(::Mrg::Grid::ConfigClient::Store), @store.console)

            serialized = s.serialize

            if @outfile != "--" then
              File.open(@outfile, "w") do |of|
                of.write(serialized.to_yaml)
              end
            else
              puts serialized.to_yaml
            end
            
            0
          end
          
        end

        Mrg::Grid::Config::Shell::COMMANDS['dump'] = Dump
        
      end
    end
  end
end
