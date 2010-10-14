#!/usr/bin/env ruby

# explain:  where does this node's configuration come from?
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
        class Explain
          def initialize(storeclient, name, op=:skel)

            @op = op
            @store = storeclient
            @name = name

            @options = {}
            @oparser = OptionParser.new do |opts|
              
              opname = "explain"
              
              opts.banner = "Usage:  wallaby #{opname} nodename\nOutputs an annotated display of this node's configuration."
                
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
            
            if args.length == 0
              puts "fatal:  you must specify a node to explain"
            end
            
            @nodes = args
            act
          end
          
          def act(kwargs=nil)
            @nodes.each do |node|
              node = @store.getNode(node)
              exp = explain_one_node(node)
              config = node.getConfig
              
              puts "### Explaining the configuration for #{node.name}"
              config.each do |param, value|
                puts "# #{param} #{exp[param] || "has no explanation"}"
                puts "#{param} = #{value}"
              end
              
            end
            
            0
          end
          
          private
          def explain_one_node(node)
            explanation = {"WALLABY_CONFIG_VERSION"=>"is set automatically"}
            
            memberships = [@store.getDefaultGroup] + node.memberships.reverse.map {|gn| @store.getGroupByName(gn)} + [node.identity_group]
            
            memberships.each do |group|
              group.features.each do |f|
                explain_one_feature(f, ", which is installed on #{group.display_name}", explanation)
              end
              
              group.params.keys.each do |param|
                explanation[param] = "is set explicitly in #{group.display_name}"
              end
            end
            
            explanation
          end
          
          def explain_one_feature(f, suffix, explanation)
            f = @store.getFeature(f)
            
            f.included_features.reverse_each do |inc|
              explain_one_feature(inc, ", which is included by #{f.name}#{suffix}", explanation)
            end
            
            f.param_meta.each do |param, meta_map|
              explanation[param] = "#{meta_map['uses_default'] ? "is set to use its default value in" : "is explicitly set in"} #{f.name}#{suffix}"
            end
          end
        end

        Mrg::Grid::Config::Shell::COMMANDS['explain'] = Explain
        
      end
    end
  end
end
