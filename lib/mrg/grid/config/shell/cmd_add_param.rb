#!/usr/bin/env ruby

# add_param:  wallaby shell add-param and modify-param functionality
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
        module ParamOps
          def api_messages
            @api_messages ||= {:kind=>:setKind, :default_val=>:setDefault, :description=>:setDescription, :must_change=>:setMustChange, :level=>:setVisibilityLevel, :needsRestart=>:setRequiresRestart}.freeze
          end

          def api_accessors
            @api_accessors ||= [:kind, :default, :description, :must_change, :requires_restart, :visibility_level, :depends, :conflicts]
          end

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
              opts.banner = "Usage:  wallaby #{self.class.opname} param-name [...] [param-options]"
              
              opts.on("-h", "--help", "displays this message") do
                puts @oparser
                exit
              end
              
              if supports_options
                {:kind=>String, :default_val=>String, :description=>String, :must_change=>{"yes"=>true, "no"=>false, "YES"=>true, "NO"=>false}, :level=>Integer, :needsRestart=>{"yes"=>true, "no"=>false, "YES"=>true, "NO"=>false}}.each do |option, kind|
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
              puts "#{gerund.capitalize} the following param: #{name}#{" with #{@options.inspect}" if supports_options}" if show_banner
              
              begin
                param = store.send(storeop, name)
                entity_callback(param)
                if supports_options
                  @options.each do |option, value|
                    msg = api_messages[option]
                    param.send(msg, value)
                  end
                end
              rescue => ex
                puts "warning:  couldn't #{verb == "add" ? "create" : "find"} #{noun} #{name}" + (ENV['WALLABY_SHELL_DEBUG'] ? " (#{ex.inspect})" : "")
              end
            end
            
            0
          end
        end
        
        class AddParam < Command
          include ParamOps
          
          def self.opname
            "add-param"
          end

          def self.description
            "Adds a parameter to the store."
          end

          def storeop
            :addParam
          end

          register_callback :after_option_parsing, :post_arg_callback
        end
        
        class ModifyParam < Command
          include ParamOps
          
          def self.opname
            "modify-param"
          end

          def self.description
            "Alters metadata for a parameter in the store."
          end

          def storeop
            :getParam
          end

          register_callback :after_option_parsing, :post_arg_callback
        end
        
        class RemoveParam < Command
          include ParamOps
          
          def self.opname
            "remove-param"
          end
          
          def self.description
            "Deletes a parameter from the store."
          end
          
          def supports_options
            false
          end
          
          def storeop
            :removeParam
          end

          register_callback :after_option_parsing, :post_arg_callback
        end
        
        class ShowParam < Command
          include ParamOps
          
          def self.opname
            "show-param"
          end
          
          def self.description
            "Displays metadata about a parameter."
          end
          
          def supports_options
            false
          end
          
          def storeop
            :getParam
          end
          
          def show_banner
            false
          end

          def entity_callback(param)
            puts "#{param.name}"
            api_accessors.each do |k|
              puts "  #{k}:  #{param.send(k).inspect}"
            end
          end

          register_callback :after_option_parsing, :post_arg_callback
        end
      end
    end
  end
end
