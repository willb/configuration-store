#!/usr/bin/env ruby

# load:  load a snapshot from a file
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
        module LoadSupport
          class LegacyInterface
            def command
              "load"
            end
            
            def banner
              "Usage: wallaby-load [options] file"
            end
            
            def collect_specific_options(opts, specific_options)
              opts.on("-a", "--activate", "attempt to activate config after loading") do
                specific_options << "--activate"
              end

              opts.on("-q", "--quiet", "do not provide progress on load feedback") do
                specific_options << "--activate"
              end

              opts.on("-v", "--verbose", "provide more progress on load feedback") do
                specific_options << "--verbose"
              end              
            end
            
            include ::Mrg::Grid::Config::Shell::GenericLegacyInterface
          end

          class SimpleLog
            def initialize(*ms)
              @accepted_messages = ms.map {|msg| msg.to_s}.uniq
            end

            def method_missing(m, *args)
              puts args.map {|arg| arg.class == String ? arg : arg.inspect}.join(" ") if accepts?(m)
            end

            private
            def accepts?(msg)
              @accepted_messages.include? msg.to_s
            end
          end
        end
        
        class Load < Command
          def self.opname
            "load"
          end
          
          def self.description 
            "Loads a wallaby snapshot from SNAPFILE."
          end
          
          def init_option_parser
            OptionParser.new do |opts|
              opts.banner = "Usage:  wallaby #{self.class.opname} SNAPFILE\n#{self.class.description}."
                
              opts.on("-h", "--help", "displays this message") do
                puts @oparser
                exit
              end
              
              opts.on("-a", "--activate", "attempt to activate config after loading") do
                @activate = true
              end

              opts.on("-q", "--quiet", "do not provide progress on load feedback") do
                if @verbosity && @verbosity != :quiet
                  puts "Error:  --quiet and --verbose are mutually exclusive options"
                  raise OptionParser::InvalidOption.new("Error:  --quiet and --verbose are incompatible options")
                end
                @verbosity = :quiet
                Mrg::Grid::SerializedConfigs::ConfigLoader.log = nil
              end

              opts.on("-v", "--verbose", "provide more progress on load feedback") do
                if @verbosity && @verbosity != :verbose
                  puts "Error:  --quiet and --verbose are mutually exclusive options"
                  raise OptionParser::InvalidOption.new("Error:  --quiet and --verbose are incompatible options")
                end
                @verbosity = :verbose
                Mrg::Grid::SerializedConfigs::ConfigLoader.log = LoadSupport::SimpleLog.new(:info, :debug)
              end
            end
          end

          def init_log(*args)
            Mrg::Grid::SerializedConfigs::ConfigLoader.log = LoadSupport::SimpleLog.new(:info)
          end
          
          register_callback :before_option_parsing, :init_log

          def init_input(*args)
            @input = (args.size > 0 ? open(args[0]) : $stdin)
          end
          
          register_callback :after_option_parsing, :init_input
          
          def act(kwargs=nil)
            
            @store.storeinit("resetdb"=>"yes")

            s = Mrg::Grid::SerializedConfigs::ConfigLoader.new(@store, @input.read)

            s.load

            if @activate
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
            end
            return 0
          end          
        end
      end
    end
  end
end
