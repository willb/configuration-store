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
      class LightweightConfig
        attr_accessor :groups, :version
        
        def init
          self.groups = []
        end
        
        def to_hash
          result = self.groups.inject({}) do |config, group|
            gname = VersionedNode.name_for_group(group)
            gconfig = ConfigVersion.getVersionedNodeConfig(gname, version)
            
            gconfig.each do |param, value|
              ValueUtil::apply!(config, param, value)
            end
            
            config
          end
          
          if ConfigUtils.should_fix_broken_configs?
            result.each do |param,val| 
              old_result = result[param]
              new_result = ValueUtil.strip_prefix(val)
              if old_result != new_result
                $wallaby_log.warn("found a spurious configuration value:  #{param} had value #{old_result}") if $wallaby_log
                result[param] = new_result
              end
            end
          end

          result["WALLABY_CONFIG_VERSION"] = version.to_s
          result
        end
      end
      
      module ValueUtil
        # some config values can start with something like '>=',
        # indicating that a value is to be appended to the preexisting
        # config value (if one exists).  This hash contains the kinds
        # of appending we can support, mapping from the character or
        # characters before value to the string used to delimit joined values.
        APPENDS = {'>='=>', ', '&&='=>' && ', '||='=>' || ', '?='=>Proc.new {|lt, rt| (!lt || lt=='') ? rt : lt}}
        APPEND_PROCS = {}
        APPEND_MATCHER = /^(?:(#{APPENDS.keys.map{|s| Regexp.escape(s)}.join('|')})\s*)+(.*?)\s*$/

        def self.append_match(value)
          return value.match(APPEND_MATCHER)
        end

        def self.join_proc(match)
          joiner = APPENDS[match[1]]
          if joiner.is_a?(String)
            APPEND_PROCS[joiner] ||= Proc.new {|lt,rt| "#{lt}#{joiner}#{rt}"}
          else
            joiner
          end
        end

        def self.strip_prefix(value)
          match = (value && value.match(APPEND_MATCHER))
          value = (match ? value_string(match) : value)
        end

        def self.prefix_string(match)
          match[1]
        end

        def self.value_string(match)
          match[2]
        end

        def self.has_append_match(value)
          return !!append_match(value)
        end

        # applies the value supplied to the config, appending if necessary
        def self.apply!(config, param, supplied_value, use_ssp=false)
          value = supplied_value.to_s
          if (value && match = append_match(value))
            supplied_value = value
            value = value_string(match)
            $wallaby_log.warn("ValueUtil.apply! didn't strip all append markers from '#{supplied_value}'; got '#{value}'") if ($wallaby_log && has_append_match(value)) if $wallaby_log

            jp = join_proc(match)
            ssp = use_ssp ? prefix_string(match) : ""
            config[param] = (config.has_key?(param) && config[param]) ? "#{ssp}#{jp.call(config[param], value)}" : "#{ssp}#{value}"
          else
            config[param] = value unless (config.has_key?(param) && (!value || value == ""))
          end
        end
      end

      class ExplanationHistory
        def initialize
          @ordering = Hash.new {|h,k| h[k] = h.keys.size }
        end
        
        def get(hash)
          @ordering[hash]
        end
        
        def to_a
          @ordering.sort {|a,b| a[1] <=> b[1]}.map {|k,v| v}
        end
      end
      
      module ExplanationContext
        FEATURE_INCLUDED_BY = "included-by"
        FEATURE_INSTALLED_ON = "installed-on"
        
        PARAM_DEFAULT = "set-to-default"
        PARAM_EXPLICIT = "set-explicitly"
        
        VALID_KEYS = [:param, :feature, :group, :how, :whence, :history]
        
        def self.make(args=nil)
          args ||= {}
          invalid_keys = args.keys - VALID_KEYS
          history = args.delete(:history)
          
          if invalid_keys != []
            raise RuntimeError.new("Internal error:  invalid keys passed to Explanation.make: #{invalid_keys.inspect}")
          end
          
          result = args.inject({}) do |acc, (k,v)|
            acc[k.to_s] = v
            acc
          end
          
          history ? history.get(result) : result
        end
        
        def human_readable
          
        end
      end
      
      module ConfigUtils
        def self.should_fix_broken_configs=(should_fix)
          @fix_broken_configs = should_fix
        end

        def self.should_fix_broken_configs?
          @fix_broken_configs ||= !!(ENV['WALLABY_FIX_BROKEN_CONFIGS'] && ENV['WALLABY_FIX_BROKEN_CONFIGS'] =~ /^true$/i)
        end

        # Strips prepended append markers from configuration values if
        # WALLABY_FIX_BROKEN_CONFIGS is set to "true" in the environment,
        # if ConfigUtils.should_fix_broken_configs has been set to true
        # elsewhere, or if the second parameter is non-false
        def self.fix_config_values(result, always=false)
          if should_fix_broken_configs? || always
            result.inject({}) do |acc,(k,v)| 
              acc[k] = ValueUtil.strip_prefix(v)
              acc
            end
          else
            result
          end
        end
        
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
          tmp_table_name = "\"tmp_#{::Rhubarb::Util::timestamp.to_s(26)}_#{Process.pid}_#{Thread.current.object_id.to_s(26)}\""
          # Get the config database; we want to be sure to use the same one
          # that subsystem and parameter are in
          configdb = Subsystem.db
          
          # Set up our temporary table
          configdb.execute <<-QUERY
          CREATE TEMPORARY TABLE #{tmp_table_name} (
            node STRING,
            param STRING COLLATE NOCASE
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

        STORAGE_PLAN = :lw_serialized

        def self.whatchanged(node, old_version, new_version)
          ConfigUtils.what_params_changed(getVersionedNodeConfig(node, old_version), getVersionedNodeConfig(node, new_version))
        end

        module LWSerializedVersionedConfigLookup
          module ClassMethods
            def getVersionedNodeConfig(node, ver=nil)
              ver ||= ::Rhubarb::Util::timestamp
              vnc = VersionedNodeConfig.find_freshest(:select_by=>{:node=>VersionedNode[node]}, :group_by=>[:node], :version=>ver)
              config = vnc.size == 0 ? {"WALLABY_CONFIG_VERSION"=>"0"} : vnc[0].config

              # This deeply inelegant code (ideally, it would just be 
              # "config.to_hash" in both cases, which would be a no-op 
              # if config were already a Hash) is a workaround for 
              # bz748507, which seems to crop up exclusively in old-style 
              # serialized configs
              if config.is_a?(Hash)
                ConfigUtils.fix_config_values(config)
              else
                config.to_hash
              end
            end

            def hasVersionedNodeConfig(node, ver=nil)
              ver ||= ::Rhubarb::Util::timestamp
              vnc, = VersionedNodeConfig.find_freshest(:select_by=>{:node=>VersionedNode[node]}, :group_by=>[:node], :version=>ver)
              vnc && vnc.version.version
            end

            
            # This method is exclusively used for copying over the
            # default group's most recent configuration to a 
            # newly-created node.  This results in the appearance that
            # a newly-created node was created just before the last
            # successful activation that affected the default group,
            # and ensures that it will have the same configuration as
            # all other unconfigured nodes that existed then.
            #
            # Internally, this is sort of an abuse of the lightweight
            # versioned-configuration scheme.  In the LW scheme, group
            # configurations are stored as hashes (potentially with
            # append markers on parameters), and node configurations
            # are stored as lists of group references.  But nodes that
            # receive the default group configuration via this
            # mechanism will have their first versioned configuration
            # stored as a hash.  This isn't visible to the user
            # (indeed, it is handled as part of the backwards-
            # compatibility code for the LW scheme), but it can make
            # for some confusing debugging.  Note that we forcibly
            # strip append markers from values where they appear when
            # copying the default group's configuration.
            #
            # It may be more sensible (and cleaner) to have this
            # method create a standard node lightweight configuration
            # that is marked with the timestamp of the last default
            # group activation and contains a list of memberships
            # (including the skeleton and default groups).  For now,
            # this works.
            #
            # NB: this will refuse to copy over an existing versioned config
            def dupVersionedNodeConfig(from, to, ver=nil)
              ver ||= ::Rhubarb::Util::timestamp
              vnc, = VersionedNodeConfig.find_freshest(:select_by=>{:node=>VersionedNode[from]}, :group_by=>[:node], :version=>ver)
              return 0 unless vnc
              toc, = VersionedNodeConfig.find_freshest(:select_by=>{:node=>VersionedNode[to]}, :group_by=>[:node], :version=>ver)
              toc = VersionedNodeConfig.create(:version=>vnc.version, :node=>VersionedNode[to], :config=>ConfigUtils.fix_config_values(vnc.config, true)) unless toc
              toc.version.version
            end
            
            def makeInitialConfig(to, ver=nil)
              ver ||= ::Rhubarb::Util::timestamp
              skel_config = nil
              default = Group::DEFAULT_GROUP_NAME
              skel = Group::SKELETON_GROUP_NAME
              default_config, = VersionedNodeConfig.find_freshest(:select_by=>{:node=>VersionedNode[VersionedNode.name_for_group(default)]}, :group_by=>[:node], :version=>ver)
              skel_config, =  VersionedNodeConfig.find_freshest(:select_by=>{:node=>VersionedNode[VersionedNode.name_for_group(skel)]}, :group_by=>[:node], :version=>ver) if Store::ENABLE_SKELETON_GROUP
              v_obj,version = [default_config, skel_config].map {|c| c ? [c.version, c.version.version] : [0,0]}.sort_by {|l| l[-1]}.pop

              return 0 if version == 0

              groups = Store::ENABLE_SKELETON_GROUP ? [default, skel] : [default]
              toc, = VersionedNodeConfig.find_freshest(:select_by=>{:node=>VersionedNode[to]}, :group_by=>[:node], :version=>ver)
              
              unless toc
                config = LightweightConfig.new
                config.version = version
                config.groups = groups
                toc = VersionedNodeConfig.create(:version=>v_obj, :node=>VersionedNode[to], :config=>config)
              end
              
              toc.version.version
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
        qmf_class_name 'ConfigVersion'
        
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
        
        expose :getNodeConfig do |args|
          args.declare :node, :lstr, :in, "The node name to inspect."
          args.declare :config, :map, :out, "This node's configuration."
        end
        
        def setNodeConfig(node, config, dofail=true)
          internal_set_node_config(node, config)
        end
        
        private
        
        include LWSerializedVersionedConfigLookup
      end
      
      class VersionedNode
        include ::Rhubarb::Persisting
        
        declare_column :name, :text
        
        DEFAULT_NODE = "+++DEFAULT"
        
        def self.name_for_group(gn)
          gn == DEFAULT_NODE ? gn : "+++#{gn}"
        end

        def is_group?
          name.slice(0,3) == "+++"
        end

        def realname
          if is_group? && name != DEFAULT_NODE
            name.slice(3,name.size)
          else
            name
          end
        end

        def self.[](nm)
          find_first_by_name(nm) || create(:name=>nm)
        end
      end
      
      # "serialized object" model of versioned config
      class VersionedNodeConfig
        include ::Rhubarb::Persisting
        
        declare_column :version, :integer, references(ConfigVersion, :on_delete=>:cascade)
        declare_column :node, :integer, references(VersionedNode, :on_delete=>:cascade)

        declare_custom_query :find_spurious, <<-QUERY
        SELECT row_id, version, node, config FROM
            (SELECT version AS dup_v, 
                    node AS dup_n,
                    config AS dup_c,
                    count(version) AS versions 
             FROM __TABLE__
             GROUP BY version, node)
          JOIN
            (SELECT row_id, 
                    version,
                    node,
                    config
             FROM __TABLE__)
            ON dup_v = version AND
               dup_n = node
          JOIN
            (SELECT version AS default_v,
                    node AS default_n,
                    config AS default_c
             FROM __TABLE__)
            ON default_v = dup_v AND
               default_c = config
        WHERE default_n in (SELECT row_id FROM #{VersionedNode.table_name} WHERE name = #{VersionedNode::DEFAULT_NODE.inspect}) AND
              versions > 1
        QUERY

        def self.delete_spurious
          db.execute <<-QUERY
          DELETE FROM #{table_name} WHERE row_id IN (
            SELECT row_id FROM
                (SELECT version AS dup_v, 
                        node AS dup_n,
                        config AS dup_c,
                        count(version) AS versions 
                 FROM #{table_name}
                 GROUP BY version, node)
              JOIN
                (SELECT row_id, 
                        version,
                        node,
                        config
                 FROM #{table_name})
                ON dup_v = version AND
                   dup_n = node
              JOIN
                (SELECT version AS default_v,
                        node AS default_n,
                        config AS default_c
                 FROM #{table_name})
                ON default_v = dup_v AND
                   default_c = config
            WHERE default_n in (SELECT row_id FROM #{VersionedNode.table_name} WHERE name = #{VersionedNode::DEFAULT_NODE.inspect}) AND
                  versions > 1
          )
          QUERY
        end

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
