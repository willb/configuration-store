#!/usr/bin/env ruby

# snapshot:  wallaby shell list-, make-, and load-snapshot functionality
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
        class SnapshotBase
          def initialize(storeclient, name, op=:makeSnapshot)
            sb_initialize(storeclient, name, op)
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
            
            if args.size != 1 && @op != :listSnapshots
              puts "error:  you must specify exactly one snapshot name"
              puts @oparser
              return
            end
            
            @name = args[0]
            
            act
          end
          
          def act(kwargs=nil)
            param = @store.send(@op, @name)
          end
          
          private
          
          def sb_initialize(storeclient, name, op)
            @op = op
            @store = storeclient
            @name = name
            @options = {}
            @oparser = OptionParser.new do |opts|
              
              opname = case @op
              when :makeSnapshot then "make-snapshot SNAPSHOT-NAME"
              when :loadSnapshot then "load-snapshot SNAPSHOT-NAME"
              when :listSnapshots then "list-snapshots"
                
              else raise "Internal error; invalid op #{@op}"
              end
              
              opts.banner = "Usage:  wallaby #{opname}"
                
              opts.on("-h", "--help", "displays this message") do
                puts @oparser
                exit
              end
            end
          end
        end
        
        class MakeSnapshot < SnapshotBase
          Mrg::Grid::Config::Shell::COMMANDS['make-snapshot'] = MakeSnapshot
        end
        
        class LoadSnapshot < SnapshotBase
          Mrg::Grid::Config::Shell::COMMANDS['load-snapshot'] = LoadSnapshot
          def initialize(storeclient, name, op=:loadSnapshot)
            sb_initialize(storeclient, name, op)
          end
        end
         
        class ListSnapshots < SnapshotBase
          Mrg::Grid::Config::Shell::COMMANDS['list-snapshots'] = ListSnapshots
          
          def initialize(storeclient, name, op=:listSnapshots)
            sb_initialize(storeclient, name, op)
          end

          def act(kwargs=nil)
            @store.console.objects(:class=>"Snapshot").each do |snap|
              puts "#{snap.name}"
            end
          end
        end
      end
    end
  end
end
