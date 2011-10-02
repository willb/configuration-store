# param:  wallaby shell param crud functionality
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

require 'mrg/grid/config/shell/entity_ops'

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

          def accessor_options
            @accessor_options ||= {:kind=>String, :default_val=>String, :description=>String, :must_change=>{"yes"=>true, "no"=>false, "YES"=>true, "NO"=>false}, :level=>Integer, :needsRestart=>{"yes"=>true, "no"=>false, "YES"=>true, "NO"=>false}}
          end

          def noun
            "parameter"
          end

        end          

        class AddParam < Command
          include EntityOps
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
          include EntityOps
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
          include EntityOps
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
          include EntityOps
          include ParamOps
          
          def self.opname
            "show-param"
          end
          
          def self.description
            "Displays metadata about a parameter in the store."
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

        class ListParam < Command
          def self.opname
            "list-params"
          end

          def self.opargs
            ""
          end

          def self.description
            "Lists all the parameter names in the store."
          end

          def supports_options
            false
          end

          def act
            store.console.objects(:class=>"Parameter").each do |param|
              puts "#{param.name}"
            end
            0
          end
        end

        class AttachParam < Command
          def self.opname
            "attach-params"
          end

          def self.opargs
            ""
          end

          def self.description
            "Modifies parameter/value pairs attached to an entity."
          end

          def supports_options
            false
          end

          def init_option_parser
            @options = [{:opt_name=>:action, :mod_func=>:upcase},
                        {:opt_name=>:type, :mod_func=>:capitalize},
                        {:opt_name=>:name, :mod_func=>:to_s}]
            str_o = ""
            @options.each do |o|
              str_o += "#{o[:opt_name].to_s.upcase} "
            end

            OptionParser.new do |opts|
              opts.banner = "Usage:  wallaby #{self.class.opname} #{str_o.strip} PARAM[=VALUE]\n#{self.class.description}"

              opts.on("-h", "--help", "displays this message") do
                puts @oparser
                exit
              end
            end
          end

          def verify_args(*args)
            valid = {:type=>[:Node, :Group, :Feature, :Subsystem], :action=>[:ADD, :REMOVE, :REPLACE]}
            @input = {}
            @arg_error = false

            dup_args = args.dup

            @options.each do |opt|
              oname = opt[:opt_name]
              ofunc = opt[:mod_func]
              input = dup_args.shift
              if input == nil
                puts "fatal: you must specify a #{opt[:opt_name].to_s.upcase}"
                @arg_error = true
              else
                @input["orig_#{oname}".intern] = input
                @input[oname] = input.send(ofunc)
              end
            end

            if @arg_error == false
              valid.keys.each do |key|
                if not valid[key].include?(@input[key].intern)
                  puts "#{@input["orig_#{key}".intern]} is an invalid #{key.to_s.upcase}"
                  @arg_error = true
                end
              end
            end

            @params = {}
            dup_args.each do |a|
              tmp = a.split("=", 2)
              @params[tmp[0]] = 0 if tmp.length == 1
              @params[tmp[0]] = tmp[1] if tmp.length == 2
            end
            # Work around paramter naming issue
            @params.each do |k,v|
              @params.delete(k)
              @params[store.getParam(k).name] = v
            end
          end

          register_callback :after_option_parsing, :verify_args

          def act
            result = 0

            if @arg_error == true
              result = 1
            elsif store.send("check#{@input[:type]}Validity", [@input[:name]]) != []
              puts "Invalid #{@input[:type]} #{@input[:name]}"
              result = 1
            else
              method = Mrg::Grid::MethodUtils.find_store_method("get#{@input[:type].slice(0,4)}")
              obj = store.send(method, @input[:name])
              if @input[:type] == "Node"
                obj = obj.identity_group
              end
              if @input[:type] == "Subsystem"
                obj.modifyParams(@input[:action], @params.keys, {})
              else
                obj.modifyParams(@input[:action], @params, {})
              end
            end

            result
          end
        end
      end
    end
  end
end
