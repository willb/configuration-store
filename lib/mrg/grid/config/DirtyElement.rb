# DirtyElement.rb:  wallaby dirty list
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

require 'mrg/grid/config'

module Mrg
  module Grid
    module Config
      class DirtyElement
        include ::Rhubarb::Persisting
        KIND_EVERYTHING = 1 << 0
        KIND_NODE = 1 << 16
        KIND_GROUP = 1 << 2
        KIND_PARAMETER = 1 << 3
        KIND_FEATURE = 1 << 1
        KIND_SUBSYSTEM = 1 << 4
        
        KINDS = Hash[*DirtyElement.constants.inject([]) {|acc, val| cn = val.to_s ; (acc << DirtyElement.const_get(cn) << cn.slice(5..-1) if cn =~ /^KIND_/)}]
        
        declare_column :kind, :integer, :not_null
        declare_column :node, :integer, references(Node, :on_delete=>:cascade)
        declare_column :grp, :integer, references(Group, :on_delete=>:cascade)
        declare_column :parameter, :integer, references(Parameter, :on_delete=>:cascade)
        declare_column :feature, :integer, references(Feature, :on_delete=>:cascade)
        declare_column :subsystem, :integer, references(Subsystem, :on_delete=>:cascade)
        
        declare_custom_query :get_dirty_list, "SELECT * FROM __TABLE__ ORDER BY kind ASC"
        
        def self.dirty_node(node)
          self.create(:kind=>KIND_NODE, :node=>node) unless self.find_first_by_node(node)
        end
        
        def self.dirty_group(group)
          self.create(:kind=>KIND_GROUP, :grp=>group) unless self.find_first_by_grp(group)
        end
        
        def self.dirty_parameter(param)
          self.create(:kind=>KIND_PARAMETER, :parameter=>param) unless self.find_first_by_parameter(param)
        end
        
        def self.dirty_feature(feature)
          self.create(:kind=>KIND_FEATURE, :feature=>feature) unless self.find_first_by_feature(feature)
        end
        
        def self.dirty_subsystem(subsystem)
          self.create(:kind=>KIND_SUBSYSTEM, :subsystem=>subsystem) unless self.find_first_by_subsystem(subsystem)
        end
        
        def self.dirty_default_group
          self.create(:kind=>KIND_EVERYTHING) unless self.find_first_by_kind(KIND_EVERYTHING)
        end
        
        def to_pair
          pair = {"kind"=>KINDS[self.kind]}
          pair["name"] = case self.kind
            when KIND_NODE then self.node.name
            when KIND_GROUP then self.grp.name
            when KIND_FEATURE then self.feature.name
            when KIND_PARAMETER then self.parameter.name
            when KIND_SUBSYSTEM then self.subsystem.name
            when KIND_EVERYTHING then "all entities are due for validation"
          end
        end
      end
    end
  end
end
