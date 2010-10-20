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
          MESSAGES = {:kind=>:setKind, :default_val=>:setDefault, :description=>:setDescription, :must_change=>:setMustChange, :level=>:setVisibilityLevel, :needsRestart=>:setRequiresRestart}

          def init_option_parser
            @options = {}
            OptionParser.new do |opts|
              opts.banner = "Usage:  wallaby #{self.class.opname == "add-param" ? "add-param" : "modify-param"} param-name [...] [param-options]"
              
              opts.on("-h", "--help", "displays this message") do
                puts @oparser
                exit
              end
              
              {:kind=>String, :default_val=>String, :description=>String, :must_change=>{"yes"=>true, "no"=>false, "YES"=>true, "NO"=>false}, :level=>Integer, :needsRestart=>{"yes"=>true, "no"=>false, "YES"=>true, "NO"=>false}}.each do |option, kind|
                opts.on("--#{option.to_s.gsub(/([A-Z])/) {|c| "_#{c.downcase}"}.sub("_","-")} VALUE", kind, "Sets the #{option} property of the #{self.class.opname=="add-param" ? "newly-created" : "modified"} parameter") do |value|
                  if @options[option]
                    exit_with(1, "You may only specify one --#{option.to_s.gsub(/([A-Z])/) {|c| "_#{c.downcase}"}.sub("_","-")} option per invocation")
                  end
                  @options[option] = value
                end
              end
            end
          end

          def post_arg_callback(*args)
            puts args.inspect
            @args = args.dup
          end

          def act
            
            @args.each do |name|
              puts "#{self.class.opname == "add-param" ? "Creating" : "Modifying"} the following param: #{name} with #{@options.inspect}"
              
              begin
                param = store.send(storeop, name)
                @options.each do |option, value|
                  msg = MESSAGES[option]
                  param.send(msg, value)
                end
              rescue => ex
                puts "warning:  couldn't #{self.class.opname == "add-param" ? "create" : "find"} parameter #{name}"
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
            "Alters a parameter in the store."
          end

          def storeop
            :getParam
          end

          register_callback :after_option_parsing, :post_arg_callback
        end
      end
    end
  end
end
