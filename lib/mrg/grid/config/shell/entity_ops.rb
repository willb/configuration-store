# entity_ops:  generic interface to modify wallaby entities; just add specifics!
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

require 'mrg/grid/config/shell/entity_ops.rb'

module Mrg
  module Grid
    module Config
      module Shell
        module EntityOps
          def verb
            self.class.opname.split("-").shift
          end
          
          def gerund
            self.class.opname.split("-").shift.sub(/(e|)$/, "ing")
          end
          
          def noun
            self.class.opname.split("-").pop
          end
          
          def init_option_parser
            @options = {}
            OptionParser.new do |opts|
              opts.banner = "Usage:  wallaby #{self.class.opname} #{noun}-name [...] [#{noun}-options]"
              
              opts.on("-h", "--help", "displays this message") do
                puts @oparser
                exit
              end
              
              if supports_options
                accessor_options.each do |option, kind|
                  opts.on("--#{option.to_s.gsub(/([A-Z])/) {|c| "_#{c.downcase}"}.sub("_","-")} VALUE", kind, "Sets the #{option} property of the #{verb=="add" ? "newly-created" : "modified"} #{noun}", "   (valid values are #{kind.is_a?(Hash) ? kind.keys.map {|k| '"' + k.downcase + '"'}.sort.uniq.reverse.join(", ") : "#{kind.to_s.downcase}s"})") do |value|
                    if @options[option]
                      exit!(1, "You may only specify one --#{option.to_s.gsub(/([A-Z])/) {|c| "_#{c.downcase}"}.sub("_","-")} option per invocation")
                    end
                    @options[option] = value
                  end
                end
              end
            end
          end

          def post_arg_callback(*args)
            @args = args.dup
          end

          def supports_options
            true
          end

          def entity_callback(arg)
            nil
          end

          def show_banner
            true
          end

          def act
            
            @args.each do |name|
              puts "#{gerund.capitalize} the following #{noun}: #{name}#{" with #{@options.inspect}" if supports_options}" if show_banner
              
              begin
                ent = store.send(storeop, name)
                entity_callback(ent)
                if supports_options
                  @options.each do |option, value|
                    msg = api_messages[option]
                    ent.send(msg, value)
                  end
                end
              rescue => ex
                puts "warning:  couldn't #{verb == "add" ? "create" : "find"} #{noun} #{name}" + (ENV['WALLABY_SHELL_DEBUG'] ? " (#{ex.inspect})" : "")
              end
            end
            
            0
          end
        end        
      end
    end
  end
end
