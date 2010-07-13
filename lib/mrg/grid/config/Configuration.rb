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
      
      class ReconfigEventMap
        # maps from subsystem names to lists of nodes
        attr_accessor :restart, :reconfig
        
        def initialize(restart=nil, reconfig=nil)
          self.restart = restart || Hash.new {|h,k| h[k] = Set.new}
          self.reconfig = reconfig || Hash.new {|h,k| h[k] = Set.new}
        end
        
        # returns a newly-allocated event map consisting of the 
        # algebraic join of this map and other
        def |(other)
          # basic rules for partial ordering of event maps:
          #  1.  reconfig: {X=>[Y]} >= reconfig: {}
          #  2.  reconfig: {X=>[Y,Z]} >= reconfig: {X=>[Y]}
          #  3.  reconfig: {X=>[Y], A=>[B]} >= reconfig: {X=>[Y]}
          #  4.  restart: {X=>[Y]} >= reconfig: {X=>[Y]}
          
          # XXX:  I am fairly confident that this implementation could be far more efficient
          
          self_restart = pairs(:restart)
          self_reconfig = pairs(:reconfig)
          
          other_restart = other.pairs(:restart)
          other_reconfig = other.pairs(:reconfig)
          
          join_restart = pairs2multimap((self_restart | other_restart).sort.uniq)
          join_reconfig = pairs2multimap((self_reconfig | other_reconfig).sort.uniq - join_restart)
          
          ReconfigEventMap.new(join_restart, join_reconfig)
        end
        
        def pairs(msg)
          return nil unless %w{restart reconfig}.include? msg.to_s
          self.send(msg).inject([]) {|acc, (k,v)| v.each {|elt| acc << [k,elt]}; acc}
        end
        
        private
        def pairs2multimap(pairs)
          pairs.inject(Hash.new {|h,k| h[k] = Set.new}) do |acc, (k,v)|
            acc[k] << v
            acc
          end
        end
      end
      
      # makes a ReconfigEventMap from a map from nodes to lists of changed parameters
      module ReconfigEventMapBuilder
        def self.build(in_map)
          tmp_table_name = "tmp_#{::Rhubarb::Util::timestamp.to_s(26)}_#{Process.pid}_#{Thread.current.object_id.to_s(26)}"
          # Get the config database; we want to be sure to use the same one
          # that subsystem and parameter are in
          configdb = Subsystem.db
          
          # Set up our temporary table
          configdb.execute <<-QUERY
          CREATE TEMPORARY TABLE #{tmp_table_name} (
            node STRING,
            param STRING
          )
          QUERY
          
          # Populate the temporary table
          in_map.each do |node, params|
            params.each do |param|
              configdb.execute("INSERT INTO #{tmp_table_name} (node, param) VALUES (?, ?)", node, param)
            end
          end
          
          # Find the subsystem information we need for each parameter
          rows = configdb.execute <<-QUERY
          SELECT node, MAX(needsRestart) AS restart, subsys FROM
            (SELECT node, parameter.row_id AS pid, 
                    needsRestart, subsystem.name AS subsys 
                FROM #{tmp_table_name}, parameter, subsystemparams, subsystem 
                WHERE parameter.name = #{tmp_table_name}.param AND 
                      subsystemparams.dest = pid AND 
                      subsystem.row_id = subsystemparams.source
            ) GROUP BY node, subsys
          QUERY
          
          result = ReconfigEventMap.new
          
          rows.each do |row|
            restart_val = row["restart"]
            if restart_val.to_s.downcase == "true" || restart_val.to_s == "1"
              result.restart[row["subsys"]] << row["node"]
            else
              result.reconfig[row["subsys"]] << row["node"]
            end
          end
          
          configdb.execute "DROP TABLE #{tmp_table_name}" rescue nil
          
          result
        end
      end
      
      class ConfigVersion
        include ::Rhubarb::Persisting
        include ::SPQR::Manageable

        STORAGE_PLAN = :serialized

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
              ver ||= ::Rhubarb::Util::timestamp
              vnc = VersionedNodeConfig.find_freshest(:select_by=>{:node=>VersionedNode[node]}, :group_by=>[:node], :version=>ver)
              vnc.size == 0 ? {"WALLABY_CONFIG_VERSION"=>0} : vnc[0].config
            end
            
            def dupVersionedNodeConfig(from, to, ver=nil)
              ver ||= ::Rhubarb::Util::timestamp
              vnc, = VersionedNodeConfig.find_freshest(:select_by=>{:node=>VersionedNode[from]}, :group_by=>[:node], :version=>ver)
              return 0 unless vnc
              to = VersionedNodeConfig.create(:version=>vnc.version, :node=>VersionedNode[to], :config=>vnc.config.dup)
              vnc.version.version
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
        
        DEFAULT_NODE = "+++DEFAULT"
        
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
        
        declare_column :version, :integer, references(ConfigVersion, :on_delete=>:cascade)
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
        
        declare_column :version, :integer, references(ConfigVersion, :on_delete=>:cascade)
        declare_column :node, :integer, references(VersionedNode, :on_delete=>:cascade)
        
        declare_index_on :node
        declare_index_on :version

        # config should be a hash of name->value pairs
        declare_column :config, :object

        alias :rhubarb_initialize :initialize
        
        def initialize(tup)
          rhubarb_initialize(tup)
          ver = self.version.respond_to?(:version) ? self.version.version : self.version
          update(:created, ver)
          self
        end

      end
    end
  end
end
