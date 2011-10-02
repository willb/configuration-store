# cmd_relationships: Create relationships between entities
#
#  Copyright (c) 2009--2010 Red Hat, Inc.
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
        module RelationshipOps
          def supports_options
            false
          end

          def sub_group_for_node
            true
          end

          def options
            [{:opt_name=>:action, :mod_func=>:upcase}, {:opt_name=>:target, :mod_func=>:to_s}]
          end

          def opargs
            str_o = ""
            options.each do |o|
              str_o += "#{o[:opt_name].to_s.upcase} "
            end
            str_o + "NAME"
          end

          def self.included(receiver)
            if receiver.respond_to?(:register_callback)
              receiver.register_callback :after_option_parsing, :parse_args
            end
          end

          def parse_args(*args)
            actions = [:ADD, :REMOVE, :REPLACE]
            @input = {}
            @arg_error = false

            dup_args = args.dup

            self.options.each do |opt|
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
            if (not actions.include?(@input[:action].intern)) && (arg_error == false)
                puts "fatal: #{@input[:orig_action]} is an invalid action"
                @arg_error = true
            end

            @relationships = []
            dup_args.each do |a|
              @relationships << a
            end
            @relationships.uniq!
          end

          def init_option_parser
            OptionParser.new do |opts|
              opts.banner = "Usage:  wallaby #{self.class.opname} [options] #{opargs}\n#{self.class.description}"

              opts.on("-h", "--help", "displays this message") do
                puts @oparser
                exit
              end

              opts.on("-p", "--priority PRI", "priority when adding") do |p|
                @priority = p.to_i
              end
            end
          end

          def verify_target(type)
            store.send("check#{type}Validity", [@input[:target]])
          end

          def verify_names(type)
            store.send("check#{type}Validity", @relationships)
          end

          def act
            result = 0

            if @arg_error == true
              result = 1
            else
              tmp = self.class.opname.split("-") - ["apply"]
              cname = Mrg::Grid::Config.constants.grep(/^#{tmp[0].capitalize}[^A-Z]*$/)[0]
              bad_target = verify_target(cname)
              bad_names = verify_names(cname)
              if (bad_target != []) || (bad_names != [])
                puts "Invalid TARGET: #{bad_target}" if bad_target != []
                puts "Invalid NAME: #{bad_names}" if bad_names != []
                result = 1
              else
                smethod = Mrg::Grid::MethodUtils.find_store_method("get#{cname.slice(0,5)}")
                obj = store.send(smethod, @input[:target])
                if cname == "Node" and sub_group_for_node
                  obj = obj.identity_group
                  cname = "Group"
                end
                cmethod = Mrg::Grid::MethodUtils.find_method(tmp[1].capitalize, cname).select {|m| m if m.index("modify") != nil}[0]
                if (@priority == nil) || (@input[:action] != "ADD")
                  obj.send(cmethod, @input[:action], @relationships, {})
                else
                  get = Mrg::Grid::Config.const_get(cname).get_from_set(cmethod.intern)
                  cur = obj.send(get)
                  cnt = 0
                  @relationships.select {|x| cur.include?(x)}.each {|y| cnt += 1 if cur.index(y) < @priority}
                  cur = cur - @relationships
                  if @input[:action] == "ADD"
                    cur.insert(@priority - cnt, *@relationships).compact!
                  end
                  obj.send(cmethod, "REPLACE", cur, {})
                end
              end
            end
            result
          end
        end

        class ParamConflict < Command
          include RelationshipOps

          def self.opname
            "param-conflict"
          end
        
          def self.description
            "Modify a parameter's conflicts in the store."
          end
        end

        class ParamDepend < Command
          include RelationshipOps

          def self.opname
            "param-depend"
          end
        
          def self.description
            "Modify a parameter's dependencies in the store."
          end
        end

        class FeatureConflict < Command
          include RelationshipOps

          def self.opname
            "feature-conflict"
          end
        
          def self.description
            "Modify a feature's conflicts in the store."
          end
        end

        class FeatureDepend < Command
          include RelationshipOps

          def self.opname
            "feature-depend"
          end
        
          def self.description
            "Modify a feature's dependencies in the store."
          end
        end

        class FeatureInclude < Command
          include RelationshipOps

          def self.opname
            "feature-include"
          end
        
          def self.description
            "Modify a feature's includes in the store."
          end
        end

        class NodeApply < Command
          include RelationshipOps

          def self.opname
            "apply-node-feature"
          end
        
          def self.description
            "Modify features applied to a node in the store."
          end
        end

        class GroupApply < Command
          include RelationshipOps

          def self.opname
            "apply-group-feature"
          end
        
          def self.description
            "Modify features applied to a group in the store."
          end
        end

        class NodeMembership < Command
          include RelationshipOps

          def self.opname
            "node-membership"
          end
        
          def self.description
            "Modify a node's group membership."
          end

          def sub_group_for_node
            false
          end

          def verify_names(type)
            store.send("checkGroupValidity", @relationships)
          end
        end
      end
    end
  end
end
