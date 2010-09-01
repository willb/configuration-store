#!/usr/bin/env ruby

# skel:  template wallaby-shell class
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
        class Skel
          def initialize(storeclient, name, op=:skel)

            @op = op
            @store = storeclient
            @name = name

            @options = {}
            @oparser = OptionParser.new do |opts|
              
              opname = "skel"
              
              opts.banner = "Usage:  wallaby #{opname}\nDoes nothing, successfully."
                
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
            
            act
          end
          
          def act(kwargs=nil)
            nil
          end
          
        end

        Mrg::Grid::Config::Shell::COMMANDS['skel'] = Skel
        
      end
    end
  end
end
