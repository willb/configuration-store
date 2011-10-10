# cmd_relationships: Create relationships between entities
#
#  Copyright (c) 2011 Red Hat, Inc.
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

          def actions
            [:ADD, :REMOVE, :REPLACE]
          end

          def options
            [{:opt_name=>:action, :mod_func=>:upcase, :desc=>"one of #{actions.join(", ")}"},
             {:opt_name=>:target, :mod_func=>:to_s, :desc=>"the name of the entity to act upon"},
             {:opt_name=>:name, :mod_func=>:to_s, :desc=>"the names of entities to modify relationship with"}]
          end

          def opargs
            options.collect {|x| "#{x[:opt_name].to_s.upcase}" }.join(" ") + " [...]"
          end

          def self.included(receiver)
            if receiver.respond_to?(:register_callback)
              receiver.register_callback :after_option_parsing, :parse_args
            end
          end

          def parse_args(*args)
            @input = {}

            dup_args = args.dup

            self.options.each do |opt|
              oname = opt[:opt_name]
              ofunc = opt[:mod_func]
              input = dup_args.shift
              if input == nil
                exit!(1, "you must specify a #{opt[:opt_name].to_s.upcase}")
              elsif @input.keys.length/2 < (self.options.length-1)
                @input["orig_#{oname}".intern] = input
                @input[oname] = input.send(*ofunc)
              else
                dup_args.unshift(input)
                @input[:name] = []
                dup_args.each do |a|
                  @input[:name] << a.send(*ofunc)
                end
                @input[:name].uniq!
              end
            end
            if not actions.include?(@input[:action].intern)
              exit!(1, "#{@input[:orig_action]} is an invalid action")
            end
          end

          def init_option_parser
            name = self.class.opname.split("-") 
            if options.size > 0
              d = options.collect {|o| "#{o[:opt_name].to_s.upcase} is #{o[:desc]}\n" }
            end
            OptionParser.new do |opts|
              opts.banner = "Usage:  wallaby #{name.join("-")} #{opargs} [#{(name - ["apply"])[0].upcase}-OPTIONS]\n#{self.class.description}\n#{d}"

              opts.on("-h", "--help", "displays this message") do
                puts @oparser
                exit
              end

	      opts.on("-p", "--priority PRI", "priority when modifying") do |p|
                @priority = p.to_i
              end
            end
          end

          def verify_target(type)
            store.send("check#{type}Validity", [@input[:target]])
          end

          def verify_names(type)
            store.send("check#{type}Validity", @input[:name])
          end

          def act
            result = 0

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
                obj.send(cmethod, @input[:action], @input[:name], {})
              else
                get = Mrg::Grid::Config.const_get(cname).get_from_set(cmethod.intern)
                cur = obj.send(get)
                cnt = 0
                @input[:name].select {|x| cur.include?(x)}.each {|y| cnt += 1 if cur.index(y) < @priority}
                cur = cur - @input[:name]
                if @input[:action] == "ADD"
                  cur.insert(@priority - cnt, *@input[:name]).compact!
                end
                obj.send(cmethod, "REPLACE", cur, {})
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

          def verify_names(type)
            store.send("checkFeatureValidity", @input[:name])
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

          def verify_names(type)
            store.send("checkFeatureValidity", @input[:name])
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
            store.send("checkGroupValidity", @input[:name])
          end
        end
      end
    end
  end
end
