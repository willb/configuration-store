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

      class PatchData
        include DefaultStruct
        field :params, Set
        field :features, Set
        field :subsystems, Set
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
            log.debug "#{self.class.name} IS NOT operating over QMF"
            class << self
              include InternalHelpers
            end
          else
            # operating over QMF via the config-client lib
            log.debug "#{self.class.name} IS operating over QMF"
            class << self
              include QmfHelpers
            end
          end
          
          yrepr = nil
          init_from_yaml(ymltxt)
        end
        
        def init_from_yaml(ymltxt)
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
        
        def create_relationships
          log.info("Creating relationships between store entities")
          @callbacks.each {|cb| cb.call}
          @callbacks = []
        end
        
        def dictify(ls)
          Hash[*ls.map {|obj| [obj.name, obj]}.flatten]
        end
        
        def skk(x)
          x
        end
      end

      class PatchLoader < ConfigLoader
        def init_from_yaml(ymltxt)
          if ymltxt != ""
            begin
              yrepr = YAML::parse(ymltxt).transform
  
              raise RuntimeError.new("serialized object not of the correct type") if not yrepr.is_a?(::Mrg::Grid::SerializedConfigs::Patch)
  
              @snapshot = ""
              @db_version = yrepr.db_version

              @old_nodes = dictify(yrepr.expected.nodes)
              @old_groups = dictify(yrepr.expected.groups)
              @old_params = dictify(yrepr.expected.params)
              @old_features = dictify(yrepr.expected.features)
              @old_subsystems = dictify(yrepr.expected.subsystems)
  
              @new_nodes = dictify(yrepr.updates.nodes)
              @new_groups = dictify(yrepr.updates.groups)
              @new_params = dictify(yrepr.updates.params)
              @new_features = dictify(yrepr.updates.features)
              @new_subsystems = dictify(yrepr.updates.subsystems)

              @nodes = {}
              @groups = {}
              @params = {}
              @features = {}
              @subsystems = {}
              
              @callbacks = []
            rescue Exception=>ex
              raise RuntimeError.new("Invalid Patch file; #{ex.message}")
            end
          end
        end

        def load
          if valid_db_version 
            snap_db
            update_entities
            super
          end
        end

        def revert_db
          @store.loadSnapshot(@snapshot)
        end
 
        private
        def snap_db
          t = Time.now.utc
          @snapshot = "Database upgrade to #{@db_version} automatic pre-upgrade snapshot at #{t} -- #{((t.tv_sec * 1000000) + t.tv_usec).to_s(16)}"
          if @store.makeSnapshot(@snapshot) == nil
            raise RuntimeError.new("Failed to create snapshot")
          end
        end

        def valid_db_version
          fobj = @store.getFeature("BaseDBVersion")
          if fobj != nil
            db_ver = (fobj.params["BaseDBVersion"].to_s rescue "0.0")
            temp = db_ver.split('.')
            db_major = temp[0].to_i
            db_minor = temp[1].to_i
          else
            db_minor = 0
            db_major = 0
          end
          temp = @db_version.split('.')
          patch_major = temp[0].to_i
          patch_minor = temp[1].to_i

          (patch_major > db_major) or ((patch_major <= db_major) and (patch_minor < patch_minor))
        end

        def update_entities
          update_nodes
          update_groups
          update_params
          update_features
          update_subsystems
        end

        def update_nodes
          @new_nodes.each do |name, new_node|
            if @old_nodes.exists?(name)
              log.info "Updating node '#{name}'"
              node = @store.getNode(name)
              if node.memberships != old_nodes[name].memberships
               raise RuntimeError.new("Node #{name} has unexpected group memberhsip list.  Expected '#{old_nodes[name].memberships}' got '#{node.memberships}'")
              end
              memberships = new_nodes[name].memberships
              if node.memberships != new_nodes[name].memberships
                @callbacks << lambda do
                  log.info "Updating '#{name}' memeberships"
                  node.modifyMemberships("REPLACE", listify(memberships), {})
                end
              end
            else
              @nodes[name] = new_node
            end
          end

          @old_nodes.each do |name, old_node|
            if not @new_nodes.exists?(name)
              log.info "Removing node '#{name}'"
              @store.removeNode(name)
            end
          end 
        end

        def update_groups
          @new_groups.each do |name, new_group|
            if not @old_groups.exists?(name)
              @groups[name] = new_group
            end
          end

          @old_groups.each do |name, old_group|
            if not @new_groups.exists?(name)
              log.info "Removing group '#{name}'"
              @store.removeGroup(name)
            end
          end 
        end

        def update_params
          @new_params.each do |name, new_param|
            if @old_params.exists?(name)
              log.info "Updating parameter '#{name}'"
              param = @store.getParam(name)

              [[:kind, :setKind, "type"], [:default, :setDefault, "default value"], [:description, :setDescription, "Description"], [:must_change, :setMustChange, "must_change"], [:visibility_level, :setVisibilityLevel, "visibility level"], [:needsRestart, :setRequiresRestart, "needs_restart"], [:depends, :modifyDepends, "dependencies"], [:conflicts, :modifyConflicts, "conflicts"]].each do |get, set, desc|
                cur = param.send(get)
                old = @old_params[name].send(get)
                new = @new_params[name].send(get)
                if cur != old
                  raise RuntimeError.new("Parameter #{name} has unexpected #{desc}.  Expected '#{old}' got '#{cur}'")
                end
                if cur != new
                  log.info "Updating '#{name}' #{desc}"
                  if get == :depends or get == :conflicts
                    @callbacks << lamda do
                      param.send(set, "REPLACE", listify(new), {"skip_validation"=>"true"})
                    end
                  else
                    param.send(set, new)
                  end
                end
              end
            else
              @params[name] = new_param
            end
          end

          @old_params.each do |name, old_param|
            if not @new_params.exists?(name)
              log.info "Removing parameter '#{name}'"
              @store.removeParam(name)
            end
          end 
        end

        def update_features
          @new_features.each do |name, new_feature|
            if @old_features.exists?(name)
              log.info "Updating Feature '#{name}'"
              feature = @store.getFeature(name)

              [[:params, :modifyParams, :skk, "parameters"],[:included, :modifyIncludedFeatures, :listify, "included features"],[:conflicts, :modifyConflicts, :setify, "conflicting features"],[:depends, :modifyDepends, :listify, "feature dependencies"]].each do |get,set,xform,desc|
                cur = feature.send(get)
                old = @old_features[name].send(get)
                new = @new_features[name].send(get)
                if cur != old
                  raise RuntimeError.new("Feature #{name} has unexpected #{desc}.  Expected '#{old}' got '#{cur}'")
                end
                if cur != new
                  @callbacks << lambda do
                    log.info "Updating '#{name}' #{desc}"
                    feature.send(set, "REPLACE", self.send(xform, new), {"skip_validation"=>"true"})
                  end
                end
              end
            else
              @features[name] = new_feature
            end
          end

          @old_features.each do |name, old_feature|
            if not @new_features.exists?(name)
              log.info "Removing feature '#{name}'"
              @store.removeFeature(name)
            end
          end 
        end

        def update_features
          @new_subsystems.each do |name, new_subsys|
            if @old_subsystems.exists?(name)
              log.info "Updating Subsystem '#{name}'"
              subsys = @store.getSubsys(name)

              cur = subsys.params
              old = @old_subsystems[name].params
              new = @new_subsystems[name].params
              if cur != old
                raise RuntimeError.new("Subsystem #{name} has unexpected parameter list.  Expected '#{old}' got '#{cur}'")
              end
              if cur != new
                @callbacks << lambda do
                  log.info "Updating '#{name}' parameters"
                  subsys.modifyParams("REPLACE", setify(new), {})
                end
              end
            else
              @subsystems[name] = new_subsys
            end
          end

          @old_subsystems.each do |name, old_subsys|
            if not @new_subsystems.exists?(name)
              log.info "Removing subsystem '#{name}'"
              @store.removeSubsys(name)
            end
          end 
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
