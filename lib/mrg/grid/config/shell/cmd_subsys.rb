# subsys:  wallaby shell subsys crud functionality
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
        module SubsysOps
          def api_messages
            @api_messages ||= {}.freeze
          end

          def api_accessors
            @api_accessors ||= [:name, :params]
          end

          def accessor_options
            @accessor_options ||= {}
          end
        end

        class AddSubsys < Command
          include EntityOps
          include SubsysOps
          
          def self.opname
            "add-subsystem"
          end

          def self.description
            "Adds a subsystem to the store."
          end

          def storeop
            :addSubsys
          end

          register_callback :after_option_parsing, :post_arg_callback
        end

        # Note that there is no modify-subsystem class
        
        class RemoveSubsys < Command
          include EntityOps
          include SubsysOps
          
          def self.opname
            "remove-subsystem"
          end
          
          def self.description
            "Deletes a subsystem from the store."
          end
          
          def storeop
            :removeSubsys
          end

          register_callback :after_option_parsing, :post_arg_callback
        end
        
        class ShowSubsys < Command
          include EntityOps
          include SubsysOps
          
          def self.opname
            "show-subsystem"
          end
          
          def self.description
            "Displays the properties of a subsystem."
          end
          
          def storeop
            :getSubsys
          end
          
          def supports_options
            false
          end

          def entity_callback(subsys)
            puts "#{subsys.name}"
            api_accessors.each do |k|
              puts "  #{k}:  #{subsys.send(k).inspect}"
            end
          end

          register_callback :after_option_parsing, :post_arg_callback
        end

        class ListSubsys < Command
          def self.opname
            "list-subsystems"
          end

          def self.opargs
            ""
          end

          def self.description
            "Lists all the subsystem names in the store."
          end

          def supports_options
            false
          end

          def act
            store.console.objects(:class=>"Subsystem").each do |subsys|
              puts "#{subsys.name}"
            end
            0
          end
        end
      end
    end
  end
end
