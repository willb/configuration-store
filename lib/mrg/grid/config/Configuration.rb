# Configuration:  QMF configuration entity
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

require 'spqr/spqr'
require 'rhubarb/rhubarb'

require 'set'

module Mrg
  module Grid
    module Config
      module ConfigUtils
        
        # Returns the symmetric difference of two hash tables, represented as an array of pairs
        def self.diff(c1,c2)
          s1 = Set[*c1]
          s2 = Set[*c2]
          ((s1 | s2) - (s1 & s2)).to_a
        end
        
        def self.what_params_changed(c1,c2)
          Hash[*diff(c1,c2).to_a.flatten].keys
        end
      end
      
      class ConfigVersion
        include ::Rhubarb::Persisting
        include ::SPQR::Manageable

        STORAGE_PLAN = :normalized

        def self.whatchanged(node, old_version, new_version)
          ConfigUtils.what_params_changed(getVersionedNodeConfig(node, old_version), getVersionedNodeConfig(node, new_version))
        end

        def self.whatchanged(node, old_version, new_version)
          ConfigUtils.what_params_changed(getVersionedNodeConfig(node, old_version), getVersionedNodeConfig(node, new_version))
        end

        module NormalizedVersionedConfigLookup
          module ClassMethods
            def getVersionedNodeConfig(node, ver=nil)
              version_row = VersionedNodeParamMapping.find_freshest(:select_by=>{:node=>VersionedNode[node]}, :group_by=>[:node], :version=>ver)
              cv = (version_row[0].version rescue nil)
              VersionedNodeParamMapping.find_by(:node=>VersionedNode[node], :version=>cv).inject({"WALLABY_CONFIG_VERSION"=>0}) do |acc, row|
                acc[row.param.name] = row.val
                acc
              end
            end
          end

          module InstanceMethods          
            def internal_get_node_config(node)
              node_obj = VersionedNode[node]
              VersionedNodeParamMapping.find_by(:version=>self, :node=>node_obj).inject({}) do |acc, row|
                acc[row.param.name] = row.val
                acc
              end
            end

            def internal_set_node_config(node, config)
              node_obj = VersionedNode[node]
              config.each do |param,value|
                param_obj = VersionedParam[param]
                vnpm = VersionedNodeParamMapping.create(:version=>self, :node=>node_obj, :param=>param_obj, :val=>value)
          #              vnpm.send(:update, :created, self.version)
              end
            end
          end

          def self.included(receiver)
            receiver.extend         ClassMethods
            receiver.send :include, InstanceMethods
          end
        end

        module SerializedVersionedConfigLookup
          module ClassMethods
            def getVersionedNodeConfig(node, ver=nil)
              vnc = VersionedNodeConfig.find_freshest(:select_by=>{:node=>VersionedNode[node]}, :group_by=>[:node], :version=>ver)
              vnc.size == 0 ? {"WALLABY_CONFIG_VERSION"=>0} : vnc[0].config
            end
          end

          module InstanceMethods
           def internal_get_node_config(node)
             node_obj = VersionedNode[node]
             cnfo = VersionedNodeConfig.find_by(:version=>self, :node=>node_obj)
             (cnfo && cnfo.size == 1 && cnfo[0].config) || {}
           end
          
           def internal_set_node_config(node, config)
             node_obj = VersionedNode[node]
             vnc = VersionedNodeConfig.create(:version=>self, :node=>node_obj, :config=>config)
             # vnc.send(:update, :created, self.version)
           end
          end

          def self.included(receiver)
            receiver.extend         ClassMethods
            receiver.send :include, InstanceMethods
          end
        end

        qmf_package_name 'com.redhat.grid.config'
        qmf_class_name 'Configuration'
        
        declare_column :version, :integer
        qmf_property :version, :uint64, :index=>true

        def self.[](version)
          find_first_by_version(version) || create(:version=>version)
        end

        def [](node)
          getNodeConfig(node, false)
        end
        
        def []=(node, config)
          setNodeConfig(node, config, false)
        end

        def getNodeConfig(node, dofail=true)
          internal_get_node_config(node)
        end
        
        def setNodeConfig(node, config, dofail=true)
          internal_set_node_config(node, config)
        end
        
        private
        
        case STORAGE_PLAN
        when :normalized then include NormalizedVersionedConfigLookup
        when :serialized then include SerializedVersionedConfigLookup
        end
      end
      
      class VersionedNode
        include ::Rhubarb::Persisting
        
        declare_column :name, :string
        
        def self.[](nm)
          find_first_by_name(nm) || create(:name=>nm)
        end
      end
      
      class VersionedParam
        include ::Rhubarb::Persisting
        
        declare_column :name, :string
        
        def self.[](nm)
          find_first_by_name(nm) || create(:name=>nm)
        end
      end
      
      # (mostly-)normalized model of versioned config
      class VersionedNodeParamMapping
        include ::Rhubarb::Persisting
        
        declare_column :version, :integer, references(ConfigVersion)
        declare_column :node, :integer, references(VersionedNode, :on_delete=>:cascade)
        declare_column :param, :integer, references(VersionedParam, :on_delete=>:cascade)
        declare_column :val, :string

        declare_index_on :node
        declare_index_on :version
        
        alias :rhubarb_initialize :initialize
        
        def initialize(tup)
          rhubarb_initialize(tup)
          update(:created, self.version.version)
          self
        end

      end
      
      # "serialized object" model of versioned config
      class VersionedNodeConfig
        include ::Rhubarb::Persisting
        
        declare_column :version, :integer, references(ConfigVersion)
        declare_column :node, :integer, references(VersionedNode, :on_delete=>:cascade)
        
        declare_index_on :node
        declare_index_on :version

        # config should be a hash of name->value pairs
        declare_column :config, :object

        alias :rhubarb_initialize :initialize
        
        def initialize(tup)
          rhubarb_initialize(tup)
          update(:created, self.version.version)
          self
        end

      end
    end
  end
end
