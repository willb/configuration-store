#!/usr/bin/env ruby

# apropos:  wallaby parameter apropos functionality
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
        class Apropos
          def initialize(storeclient, name, op=:apropos)

            @op = op
            @store = storeclient
            @name = name
            @use_regex = false
            @insens = nil

            @options = {}
            @oparser = OptionParser.new do |opts|
              
              opname = "apropos KEYWORD"
              
              opts.banner = "Usage:  wallaby #{opname}\nProvides a list of parameters that contain KEYWORD in their descriptions."
                
              opts.on("-h", "--help", "displays this message") do
                puts @oparser
                exit
              end

              opts.on("--regex", "interpret KEYWORD as a regular expression") do
                @use_regex = true
              end

              opts.on("-i", "--case-insensitive", "return case-insensitive matches for KEYWORD") do
                @insens = Regexp::IGNORECASE
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
            
            if args.size != 1
              puts "error:  you must specify a keyword"
              puts @oparser
              return
            end
            
            @keyword = args[0]
            
            if @use_regex
              @matches = Proc.new do |name|
                @regexp ||= Regexp.new(@keyword, @insens)
                name =~ @regexp
              end
            else
              @matches = Proc.new do |name|
                @matchkwd ||= @insens ? @keyword.downcase : @keyword
                name = name.downcase if @insens
                name.include?(@matchkwd)
              end
            end

            act
          end
          
          def act(kwargs=nil)

            params = @store.parameters.select {|p| @matches.call(p.description) }.sort_by {|prm| prm.name}

            params.each do |prm|
              puts "#{prm.name}:  #{prm.description}"
            end

          end
          
        end
        

        Mrg::Grid::Config::Shell::COMMANDS['apropos'] = Apropos
        
      end
    end
  end
end
