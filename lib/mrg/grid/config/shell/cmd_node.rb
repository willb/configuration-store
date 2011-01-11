# node:  wallaby shell node crud functionality
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
        module NodeOps
          def api_messages
            @api_messages ||= {}.freeze
          end

          def api_accessors
            @api_accessors ||= [:name, :provisioned, :last_checkin, :last_updated_version, :memberships]
          end

          def accessor_options
            @accessor_options ||= {}
          end

          def supports_options
            false
          end
        end

        class AddNode < Command
          include EntityOps
          include NodeOps
          
          def self.opname
            "add-node"
          end

          def self.description
            "Adds a node to the store."
          end

          def storeop
            :addNode
          end

          register_callback :after_option_parsing, :post_arg_callback
        end

        # Note that there is no modify-node class
        
        class RemoveNode < Command
          include EntityOps
          include NodeOps
          
          def self.opname
            "remove-node"
          end
          
          def self.description
            "Deletes a node from the store."
          end
          
          def storeop
            :removeNode
          end

          register_callback :after_option_parsing, :post_arg_callback
        end
        
        class ShowNode < Command
          include EntityOps
          include NodeOps
          
          def self.opname
            "show-node"
          end
          
          def self.description
            "Displays the properties of a node."
          end
          
          def storeop
            :getNode
          end
          
          def custom_act(arg=nil)
            store.nodes.find {|n| n.name == arg}
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
