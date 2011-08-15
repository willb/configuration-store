# config-proxies.rb:  support code for wallaby dump and restore
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

require 'set'
require 'yaml'

module Mrg
  module Grid
    module SerializedConfigs
      class MsgSink
        def method_missing(sym, *args)
          nil
        end
      end
      
      module DefaultStruct
        module Cm
          def saved_fields
            @saved_fields ||= {}
          end
          
          def field(name, kind=String)
            saved_fields[name] = kind
            attr_accessor name
          end
        end
        
        module Im
          def initialize(kwargs=nil)
            kwargs ||= {}
            sf = self.class.saved_fields

            sf.keys.each do |key|
              if kwargs[key]
                self.send("#{key}=".to_sym, kwargs[key])
              else
                what = sf[key]
                default = what.is_a?(Class) ? what.new : what
                self.send("#{key}=".to_sym, default)
              end
            end
          end
        end
        
        def self.included(receiver)
          receiver.extend         Cm
          receiver.send :include, Im
        end
      end
      
      # sort of bogus, not included in DefaultStruct in production.  Perhaps useful for testing
      module DSComparators
        def eql?(other)
          return false unless self.class == other.class
          self == other
        end
        
        def <=>(other)
          return nil unless self.class == other.class
          
          self.class.saved_fields.keys.each do |msg|
            mine = self.send(msg)
            yours = self.send(msg)
            $submine = mine
            $subyours = yours
            
            if mine.respond_to? :<=>
              result = mine <=> yours
              return result unless result == 0
            else
              result = (mine == yours || nil)
              return result if result.nil?
            end
            
            0
          end
        end
        
        def ==(other)
          self.class.saved_fields.each do |msg,default|
            mine = self.send(msg)
            yours = self.send(msg)
            
            if default == Set
              mine = (mine.to_a.sort_by {|s| s.name} rescue Set[*mine.to_a])
              yours = (yours.to_a.sort_by {|s| s.name} rescue Set[*yours.to_a])
            end
            
            unless mine == yours
              return false
            end
          end
          
          true
        end
        
        def hash
          result = {'PROXY_CLASSNAME'=>self.class.name}
          
          self.class.saved_fields.each do |msg,default|
            result[msg] = default == Set ? default[*self.send(msg)] : self.send(msg)
          end

          result.hash
        end
      end
      
      module DBHelpers
        def create_relationships
          log.info("Creating relationships between store entities")
          @callbacks.each {|cb| cb.call}
          @callbacks = []
        end
        
        def dictify(ls)
          Hash[*ls.map {|obj| [obj.name, obj]}.flatten]
        end
      end

      class Configuration 
        def initialize
          raise "Configuration proxy not implemented"
        end
      end

      class Store
        include DefaultStruct
        field :nodes, Set
        field :groups, Set
        field :params, Set
        field :features, Set
        field :subsystems, Set
      end

      class Patch
        include DefaultStruct
        field :db_version, String
        field :expected, Set
        field :updates, Set
      end

      class Feature
        include DefaultStruct
        field :name, String
        field :params, Hash
        field :included, Array
        field :conflicts, Set
        field :depends, Array
      end
      
      class Group
        include DefaultStruct
        field :name, String
        field :is_identity_group, false
        field :features, Array
        field :params, Hash
      end
      
      class Parameter
        include DefaultStruct
        field :name, String
        field :kind, String
        field :default_val, String
        field :description, String
        field :must_change, false
        field :level, 0
        field :needs_restart, false
        field :conflicts, Set
        field :depends, Set
      end
      
      class Node
        include DefaultStruct
        field :name, String
        field :idgroup, String
        field :membership, Array
        field :provisioned, true
        field :last_updated_version, 0
      end        
      
      class Subsystem
        include DefaultStruct
        field :name, String
        field :params, Set
      end
      
      class ConfigLoader
        include DBHelpers

        module InternalHelpers
          def listify(ls)
            ls
          end
         
          def setify(s)
            s.uniq
          end
        end
      
        module QmfHelpers
          def listify(ls)
            ls
          end
          
          def setify(ls)
            ls
          end
        end
      
        def ConfigLoader.log
          @log ||= MsgSink.new
        end
        
        def ConfigLoader.log=(lg)
          @log = lg
        end
        
        def log
          self.class.log
        end
        
        def initialize(store, ymltxt)
          @store = store
          
          if @store.class.to_s == "Mrg::Grid::Config::Store"
            # "internal" -- not operating over qmf
            log.debug "ConfigLoader IS NOT operating over QMF"
            class << self
              include InternalHelpers
            end
          else
            # operating over QMF via the config-client lib
            log.debug "ConfigLoader IS operating over QMF"
            class << self
              include QmfHelpers
            end
          end
          
          yrepr = nil

          begin
            yrepr = YAML::parse(ymltxt).transform

            raise RuntimeError.new("serialized object not of the correct type") if not yrepr.is_a?(::Mrg::Grid::SerializedConfigs::Store)

            @nodes = dictify(yrepr.nodes)
            @groups = dictify(yrepr.groups)
            @params = dictify(yrepr.params)
            @features = dictify(yrepr.features)
            @subsystems = dictify(yrepr.subsystems)
            
            @callbacks = []
          rescue Exception=>ex
            raise RuntimeError.new("Invalid snapshot file; #{ex.message}")
          end
          
        end
        
        def load
          create_entities
          create_relationships
        end
        
        private
        def create_entities
          create_nodes
          create_groups
          create_params
          create_features
          create_subsystems
        end
        
        def create_nodes
          @nodes.each do |name, old_node|
            log.info("Creating node '#{name}'")
            options = {}
            options["seek_versioned_config"] = old_node.last_updated_version if old_node.last_updated_version && old_node.last_updated_version > 0
            node = @store.addNodeWithOptions(name, options)
            node.makeUnprovisioned unless (old_node.provisioned)
            memberships = old_node.membership
            if memberships.size > 0
              flmemberships = listify(memberships)
              @callbacks << lambda do
                log.info("Setting memberships for node #{name}")
                log.debug("Node #{name} has memberships #{flmemberships.inspect}")
                node.modifyMemberships("ADD", flmemberships, {})
              end
            end
          end
        end
        
        def create_groups
          @groups.each do |name, old_group|            
            group = nil
            if name.index("+++") == 0
              # this is an identity or default group; don't create it
              log.info("Finding special group '#{name}'")
              group = @store.getGroup({"NAME"=>name})
            else
              log.info("Creating group '#{name}'")
              group = @store.addExplicitGroup(name)
            end
            
            if old_group.features.size > 0
              flfeatures = listify(old_group.features)
              @callbacks << lambda do
                log.info("Setting features for group #{name}")
                log.debug("Group #{name} has features #{flfeatures.inspect}")
                group.modifyFeatures("ADD", flfeatures, {})
              end
            end
            
            if old_group.params.size > 0
              @callbacks << lambda do
                log.info("Setting params for group #{name}")
                log.debug("Group #{name} has params #{old_group.params.inspect}")
                group.modifyParams("ADD", old_group.params, {})
              end
            end
          end
        end
        
        def create_params
          @params.each do |name, old_param|
            log.info "Creating parameter '#{name}'"
            
            param = @store.addParam(name)
            param.setKind(old_param.kind)
            param.setDefault(old_param.default_val) unless old_param.must_change
            param.setDescription(old_param.description)
            param.setMustChange(old_param.must_change)
            param.setVisibilityLevel(old_param.level)
            param.setRequiresRestart(old_param.needs_restart)

            {:conflicts=>:modifyConflicts,:depends=>:modifyDepends}.each do |get,set|
              if old_param.send(get).size > 0
                @callbacks << lambda do
                  log.info "Setting #{get} for parameter #{name}"
                  log.debug "#{get.to_s.capitalize} for parameter #{name} are #{old_param.send(get).inspect}"
                  param.send(set, "ADD", setify(old_param.send(get)), {"skip_validation"=>"true"})
                end
              end
            end
          end
        end
        
        def create_features
          @features.each do |name, old_feature|
            log.info "Creating feature '#{name}'"
            feature = @store.addFeature(name)
            [[:params, :modifyParams, :skk, "parameters"],[:included, :modifyIncludedFeatures, :listify, "included features"],[:conflicts, :modifyConflicts, :setify, "conflicting features"],[:depends, :modifyDepends, :listify, "feature dependencies"]].each do |get,set,xform,desc|
              if old_feature.send(get).size > 0
                @callbacks << lambda do
                  log.info "Setting #{desc} for #{name}"
                  log.debug "#{desc.capitalize} for #{name} are #{old_feature.send(get).inspect}"
                  feature.send(set, "ADD", self.send(xform, old_feature.send(get)), {"skip_validation"=>"true"})
                end
              end
            end
          end
        end
        
        def create_subsystems
          @subsystems.each do |name, old_ss|
            log.info "Creating subsystem '#{name}'"
            subsys = @store.addSubsys(name)
            if old_ss.params.size > 0
              @callbacks << lambda do
                log.info "Setting parameters for subsystem #{name}"
                log.debug "Subsystem #{name} has parameters #{old_ss.params.inspect}"
                subsys.modifyParams("ADD", setify(old_ss.params), {})
              end
            end
          end
        end
        
        def skk(x)
          x
        end
      end

      class PatchLoader
        include DBHelpers

        def initialize(store, force_upgrade=false)
          @store = store
          @force = force_upgrade
          @entities = [:nodes, :groups, :params, :features, :subsystems]
          @translator = {:nodes=>{:short=>:Node, :long=>:Node}, :groups=>{:short=>:Group, :long=>:Group}, :params=>{:short=>:Param, :long=>:Parameter}, :features=>{:short=>:Feature, :long=>:Feature}, :subsystems=>{:short=>:Subsys, :long=>:Subsystem}}
        end

        def load_yaml(ymltxt)
          begin
            yrepr = YAML::parse(ymltxt).transform
  
            raise RuntimeError.new("serialized object not of the correct type") if not yrepr.is_a?(::Mrg::Grid::SerializedConfigs::Patch)
  
            @snapshot = nil
            @db_obj = nil
            @db_version = yrepr.db_version

            @expected = yrepr.expected
            @updates = yrepr.updates

            @callbacks = []
          rescue Exception=>ex
            raise RuntimeError.new("Invalid Patch file; #{ex.message}")
          end
        end

        def PatchLoader.log
          @log ||= MsgSink.new
        end
        
        def PatchLoader.log=(lg)
          @log = lg
        end
        
        def log
          self.class.log
        end

        def load
          if valid_db_version 
            log.info "Updating database to version #{@db_version}"
            snap_db
            update_entities
          end
        end

        def revert_db
          log.info "Reverting database to state before patching attempt"
          @store.loadSnapshot(@snapshot)
        end

        def affected_entities
          changes = Hash.new {|h,k| h[k] = Hash.new {|h1,k1| h1[k1] = [] } }
          @entities.each do |type|
            @updates.send(type).keys.each do |name|
              if @expected.send(type).has_key?(name)
                changes["modify"][@translator[type][:short]].push(name)
              else
                changes["add"][@translator[type][:short]].push(name)
              end
            end
          end

          @entities.each do |type|
            @expected.send(type).keys.each do |name|
              if not @updates.send(type).has_key?(name)
                changes["delete"][@translator[type][:short]].push(name)
              end
            end
          end
          changes
        end

        def entity_details(type, name)
          accessors = {:modifyMemberships=>:memberships, :modifyFeatures=>:features, :modifyParams=>:params, :setKind=>:kind, :setDefault=>:default, :setDescription=>:description, :setMustChange=>:must_change, :setVisibilityLevel=>:visibility_level, :setRequiresRestart=>:requires_restart, :modifyDepends=>:depends, :modifyConflicts=>:conflicts, :modifyIncludedFeatures=>:included_features}
          swap = {:Node=>:nodes, :Group=>:groups, :Feature=>:features, :Parameter=>:params, :Subsystem=>:subsystems}
          details = {"expected"=>{}, "updates"=>{}}
          t = swap[type]
          if @updates.send(t).has_key?(name)
            @updates.send(t)[name].keys.each do |set|
              details["updates"][accessors[set]] = @updates.send(t)[name][set]
            end
          end

          if @expected.send(t).has_key?(name)
            details["expected"] = @expected.send(t)[name]
          end
          details
        end
 
        private
        def snap_db
          t = Time.now.utc
          @snapshot = "Database upgrade to #{@db_version} automatic pre-upgrade snapshot at #{t} -- #{((t.tv_sec * 1000000) + t.tv_usec).to_s(16)}"
          log.info "Creating snapshot named '#{@snapshot}'"
          if @store.makeSnapshot(@snapshot) == nil
            raise RuntimeError.new("Failed to create snapshot")
          end
        end

        def valid_db_version
          @db_obj = @store.getFeature("BaseDBVersion")
          if @db_obj != nil
            db_ver = (@db_obj.params["BaseDBVersion"].to_s rescue "1.4")
            temp = db_ver.split('.')
            db_major = temp[0].delete("v").to_i
            db_minor = temp[1].to_i
          else
            db_major = 1
            db_minor = 4
          end
          temp = @db_version.to_s.split('.')
          patch_major = temp[0].to_i
          patch_minor = temp[1].to_i

          (patch_major > db_major) or ((patch_major <= db_major) and (patch_minor > db_minor))
        end

        def update_entities
          @entities.each do |type|
            @updates.send(type).keys.each do |name|
              added = false
              if @store.send("check#{@translator[type][:long]}Validity", [name]) != []
                log.info "Adding #{@translator[type][:long]} '#{name}'"
                if type == :Group
                  obj = @store.send("addExplicitGroup", name)
                else
                  obj = @store.send("add#{@translator[type][:short]}", name)
                end
                added = true
              else
                log.info "Retrieving #{@translator[type][:long]} '#{name}'"
                obj = @store.send("get#{@translator[type][:short]}", name)
              end

              if obj == nil
                raise RuntimeError.new("Failed to retrieve #{@translator[type][:long]} '#{name}'")
              end

              if added == false and not @force
                @expected.send(type)[name].keys.each do |get|
                  log.info "Verifying #{@translator[type][:long]} '#{name}##{get}'"
                  current_val = obj.send(get)
                  if name == "BaseDBVersion"
                    current_val["BaseDBVersion"].delete!("v")
                  end
                  if type == :features
                    default_params = obj.param_meta.select {|k,v| v["uses_default"] == true || v["uses_default"] == 1}.map {|pair| pair[0]}
                    default_params.each {|dp_key| current_val[dp_key] = 0}
                  end
                  expected_val = @expected.send(type)[name][get]
                  if name == "BaseDBVersion"
                    expected_val["BaseDBVersion"].delete!("v")
                  end
                  begin
                    current_adj = current_val.sort
                    expected_adj = expected_val.sort
                  rescue
                    current_adj = current_val
                    expected_adj = expected_val
                  end
                  if current_adj != expected_adj
                    raise RuntimeError.new("#{@translator[type][:long]} '#{name}' has a current value of '#{current_val.inspect}' but expected '#{expected_val.inspect}'")
                  end
                end
              end

              log.info "Updating #{@translator[type][:long]} '#{name}'"
              commands = @updates.send(type)[name].keys
              if commands.include?("setMustChange")
                commands.delete("setMustChange")
                commands.insert(0, "setMustChange")
              end
              commands.each do |set|
                val = @updates.send(type)[name][set]
                if set.to_s =~ /^modify/
                  @callbacks << lambda do
                    obj.send(set, *val)
                  end
                else
                  obj.send(set, val)
                end
              end
            end
          end

          @entities.each do |type|
            @expected.send(type).keys.each do |name|
              if not @updates.send(type).has_key?(name) and not name =~ /^\+\+\+/
                log.info "Removing #{@translator[type][:long]} '#{name}'"
                @store.send("remove#{@translator[type][:short]}", [name])
              end
            end
          end

          create_relationships
        end
      end
      
      class ConfigSerializer
        module QmfConfigSerializer
          # this is a no-op if we're using ConfigClients
          def get_object(o)
            o
          end
          
          # XXX:  as of recently, this (like the analogous method in
          # InStoreConfigSerializer) duplicates effort with methods
          # in the Store client class
          def get_instances(klass)
            @console.objects(:class=>klass.to_s, :timeout=>45).map do |obj|
              ::Mrg::Grid::ConfigClient.const_get(klass).new(obj, @console)
            end
          end
        end
        
        module InStoreConfigSerializer
          # this is a no-op if we aren't over qmf
          def get_object(o)
            o
          end
          
          # XXX:  as of recently, this (like the analogous method in
          # QmfConfigSerializer) duplicates effort with (non-exposed)
          # methods in the Store class
          def get_instances(klass)
            ::Mrg::Grid::Config.const_get(klass).find_all
          end
        end
        
        def initialize(store, over_qmf=false, console=nil)
          @store = store
          @console = console if over_qmf
          @struct = Store.new
          
          if over_qmf
            class << self
              include QmfConfigSerializer
            end
          else
            class << self
              include InStoreConfigSerializer
            end
          end
        end
        
        def serialize
          @struct.nodes = serialize_nodes.sort_by {|o| o.name}
          @struct.groups = serialize_groups.sort_by {|o| o.name}
          @struct.params = serialize_params.sort_by {|o| o.name}
          @struct.features = serialize_features.sort_by {|o| o.name}
          @struct.subsystems = serialize_subsystems.sort_by {|o| o.name}
          @struct
        end
        
        private
        def serialize_nodes
          get_instances(:Node).map do |n|
            node = get_object(n)
            out = Node.new
            out.name = node.name
            out.provisioned = node.provisioned
            out.membership = fl_normalize(node.memberships)
            out.last_updated_version = node.last_updated_version
            out
          end
        end
        
        def serialize_groups
          get_instances(:Group).map do |g|
            group = get_object(g)
            out = Group.new
            out.name = group.name
            out.is_identity_group = group.is_identity_group
            out.features = fl_normalize(group.features)
            out.params = group.params
            out
          end
        end
        
        def serialize_params
          get_instances(:Parameter).map do |p|
            param = get_object(p)
            out = Parameter.new
            out.name = param.name
            out.kind = param.kind
            out.default_val = param.default.to_s
            out.description = param.description
            out.must_change = param.must_change
            out.level = param.visibility_level
            out.needs_restart = param.requires_restart
            out.conflicts = fs_normalize(param.conflicts)
            out.depends = fs_normalize(param.depends)
            out
          end
        end
        
        def serialize_features
          get_instances(:Feature).map do |f|
            feature = get_object(f)
            out = Feature.new
            out.name = feature.name
            params = feature.params
            
            # Ensure that params that should get the default values are serialized
            default_params = feature.param_meta.select {|k,v| v["uses_default"] == true || v["uses_default"] == 1}.map {|pair| pair[0]}
            default_params.each {|dp_key| params[dp_key] = 0}
            
            out.params = params
            out.included = fl_normalize(feature.included_features)
            out.conflicts = fs_normalize(feature.conflicts)
            out.depends = fl_normalize(feature.depends)
            out
          end
        end
        
        def serialize_subsystems
          get_instances(:Subsystem).map do |s|
            subsys = get_object(s)
            out = Subsystem.new
            out.name = subsys.name
            out.params = fs_normalize(subsys.params)
            out
          end
        end
        
        def fs_normalize(fs)
          fs.sort
        end
        
        def fl_normalize(fl)
          fl
        end
      end
    end
  end  
end
