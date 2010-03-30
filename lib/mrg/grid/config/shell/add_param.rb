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
        class ParamOps
          MESSAGES = {:kind=>:SetType, :default_val=>:SetDefault, :description=>:SetDescription, :must_change=>:SetDefaultMustChange, :level=>:SetVisibilityLevel, :needsRestart=>:SetRequiresRestart}

          def initialize(storeclient, name, op=:AddParam)
            po_initialize(storeclient, name, op)
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
            
            args.each do |name|
              @name = name
              puts "#{@op == :AddParam ? "Creating" : "Modifying"} the following param: #{@name} with #{@options.inspect}"
              act(@options)
            end
          end
          
          def act(kwargs)
            param = @store.send(@op, @name)
            @options.each do |option, value|
              msg = MESSAGES[option]
              param.send(msg, value)
            end
          end
          
          private
          
          def po_initialize(storeclient, name, op)
            @op = op
            @store = storeclient
            @name = name
            @options = {}
            @oparser = OptionParser.new do |opts|
              opts.banner = "Usage:  wallaby #{op == :AddParam ? "add-param" : "modify-param"} param-name [...] [param-options]"
                
              opts.on("-h", "--help", "displays this message") do
                puts @oparser
                exit
              end
              
              {:kind=>String, :default_val=>String, :description=>String, :must_change=>{"yes"=>true, "no"=>false, "YES"=>true, "NO"=>false}, :level=>Integer, :needsRestart=>{"yes"=>true, "no"=>false, "YES"=>true, "NO"=>false}}.each do |option, kind|
                opts.on("--#{option.to_s.gsub(/([A-Z])/) {|c| "_#{c.downcase}"}.sub("_","-")} VALUE", kind, "Sets the #{option} property of the #{@op==:AddParam ? "newly-created" : "modified"} parameter") do |value|
                  @options[option] = value
                end
              end
            end
          end
        end
        
        class AddParam < ParamOps
          Mrg::Grid::Config::Shell::COMMANDS['add-param'] = AddParam
        end
        
        class ModifyParam < ParamOps
          Mrg::Grid::Config::Shell::COMMANDS['modify-param'] = ModifyParam
          def initialize(storeclient, name, op=:GetParam)
            po_initialize(storeclient, name, op)
          end
        end
      end
    end
  end
end
