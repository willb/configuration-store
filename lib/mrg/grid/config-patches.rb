# config-patches.rb:  support code for patching wallaby's database
# 
# Copyright (c) 2011 Red Hat, Inc.
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

require 'yaml'
require 'rhubarb/rhubarb'
require 'mrg/grid/config'

module Mrg
  module Grid
    module PatchConfigs
      class Patch
        include Mrg::Grid::SerializedConfigs::DefaultStruct
        field :db_version, String
        field :expected, Set
        field :updates, Set
      end

      class DBVersion
        def initialize(str)
          str =~ /^[\D]*?([0-9]+)[.]([0-9]+)[\D]*?$/
          @major = $1.to_i
          @minor = $2.to_i
        end

        def major
          @major
        end

        def minor
          @minor
        end

        def <=>(ver)
          (self.major > ver.major) || (self.major <=> ver.major && self.minor <=> ver.minor)
        end

        def to_s
          "#{@major}.#{@minor}"
        end

        def to_tag
          to_s.insert(0, "DB-RELEASE-")
        end
      end

      class Database
        include Mrg::Grid::SerializedConfigs::DBHelpers

        def initialize(yml, db_ver)
          data = YAML::parse(yml).transform

          @nodes = dictify(data.nodes)
          @groups = dictify(data.groups)
          @params = dictify(data.params)
          @features = dictify(data.features)
          @subsystems = dictify(data.subsystems)
          @version = db_ver
        end

        def generate_patch(db_obj)
          @patch = Patch.new
          @patch.expected = Mrg::Grid::SerializedConfigs::Store.new
          @patch.updates = Mrg::Grid::SerializedConfigs::Store.new
          @patch.db_version = @version
          diff_nodes(db_obj.nodes)
          diff_groups(db_obj.groups)
          diff_params(db_obj.params)
          diff_features(db_obj.features)
          diff_subsystems(db_obj.subsystems)
          diff_versions(db_obj.version)
          @patch
        end

        def nodes
          @nodes
        end

        def groups
          @groups
        end

        def params
          @params
        end

        def features
          @features
        end

        def subsystems
          @subsystems
        end

        def version
          @version
        end

        private
        def make_patch_entity(new, old, methods)
          updates = Hash.new {|h,k| h[k] = Hash.new {|h1,k1| h1[k1] = {} } }
          expected = Hash.new {|h,k| h[k] = Hash.new {|h1,k1| h1[k1] = {} } }
          new.each do |name, obj|
            methods.each do |get, qmfget, set|
              if (not old.has_key?(name)) || (obj.send(get) != old[name].send(get))
                if set.to_s =~ /^modify/
                  updates[name].merge!({"#{set}"=>["REPLACE", obj.send(get), {}]})
                else
                  updates[name].merge!({"#{set}"=>obj.send(get)})
                end
                if old.has_key?(name)
                  expected[name].merge!({"#{qmfget}"=>old[name].send(get)})
                end
              end
            end
          end
          old.each do |name, obj|
            if not new.has_key?(name)
              methods.each do |get, qmfget, set|
                expected[name].merge!({"#{qmfget}"=>old[name].send(get)})
              end
            end
          end
          return updates, expected
        end

        def diff_nodes(old_nodes)
          @patch.updates.nodes, @patch.expected.nodes = make_patch_entity(@nodes, old_nodes, [[:membership, :memberships, :modifyMemberships]])
        end

        def diff_groups(old_groups)
          @patch.updates.groups, @patch.expected.groups = make_patch_entity(@groups, old_groups, [[:features, :features, :modifyFeatures], [:params, :params, :modifyParams]])
        end

        def diff_params(old_params)
          @patch.updates.params, @patch.expected.params = make_patch_entity(@params, old_params, [[:kind, :kind, :setKind], [:default_val, :default, :setDefault], [:description, :description, :setDescription], [:must_change, :must_change, :setMustChange], [:level, :visibility_level, :setVisibilityLevel], [:needs_restart, :requires_restart, :setRequiresRestart], [:depends, :depends, :modifyDepends], [:conflicts, :conflicts, :modifyConflicts]])
        end

        def diff_features(old_features)
          @patch.updates.features, @patch.expected.features = make_patch_entity(@features, old_features, [[:params, :params, :modifyParams], [:included, :included_features, :modifyIncludedFeatures], [:conflicts, :conflicts, :modifyConflicts], [:depends, :depends, :modifyDepends]])
        end

        def diff_subsystems(old_subsystems)
          @patch.updates.subsystems, @patch.expected.subsystems = make_patch_entity(@subsystems, old_subsystems, [[:params, :params, :modifyParams]])
        end

        def diff_versions(old_version)
          old_split = old_version.split(".")
          old_maj = old_split[0].to_i
          old_min = old_split[1].to_i

          new_split = @version.split(".")
          new_maj = new_split[0].to_i
          new_min = new_split[1].to_i

          if old_maj > 1 || (old_maj >= 1 && old_min > 4)
             @patch.expected.features["BaseDBVersion"] = {:params=>{"BaseDBVersion"=>"#{old_version.to_s}"}}
          end
          if new_maj > 1 || (new_maj >= 1 && new_min > 4)
             @patch.updates.features["BaseDBVersion"] = {"modifyParams"=>["REPLACE", {"BaseDBVersion"=>"v#{version.to_s}"}, {}]}
          end
        end
      end

      class PatchLoader
        include Mrg::Grid::SerializedConfigs::DBHelpers
        include Mrg::Grid::NameUtils

        def initialize(store, force_upgrade=false)
          @store = store
          @force = force_upgrade
          @entities = ::Mrg::Grid::SerializedConfigs::Store.new.public_methods(false).select {|m| m.index("=") == nil}.sort {|x,y| y <=> x }
          @valid_methods = {}
          @entities.each do |type|
            otype = obj_type(type.intern)
            klass = Mrg::Grid::Config.const_get(otype)
            qmf_methods = klass.spqr_meta.manageable_methods.map {|m| m.name}
            qmf_props = klass.spqr_meta.properties.map {|p| p.name}
            @valid_methods[otype] = qmf_methods | qmf_props
          end
          log.debug "Valid methods: #{@valid_methods.inspect}"
        end

        def load_yaml(ymltxt)
          begin
            yrepr = YAML::parse(ymltxt).transform
  
            raise RuntimeError.new("serialized object not of the correct type") if not yrepr.is_a?(::Mrg::Grid::PatchConfigs::Patch)
  
            @snapshot = nil
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

        def db_version
          @db_version
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
            type = type.intern
            otype = obj_type(type)
            @updates.send(type).keys.each do |name|
              if @expected.send(type).has_key?(name)
                changes[:modify][otype].push(name)
              else
                changes[:add][otype].push(name)
              end
            end
          end

          @entities.each do |type|
            type = type.intern
            otype = obj_type(type)
            @expected.send(type).keys.each do |name|
              if not @updates.send(type).has_key?(name)
                changes[:delete][otype].push(name)
              end
            end
          end
          changes
        end

        def entity_details(type, name)
          details = {:expected=>{}, :updates=>{}}
          t = Mrg::Grid::SerializedConfigs::Store.constants.grep(/^#{name.slice(0,5).downcase}/)
          klass = Mrg::Grid::Config.const_get(type)
          if @updates.send(t).has_key?(name)
            @updates.send(t)[name].keys.each do |set|
              cmd = klass.gen_getter(set.intern)
              if set.to_s =~ /^modify/
                details[:updates][cmd] = @updates.send(t)[name][set][1]
              else
                details[:updates][cmd] = @updates.send(t)[name][set]
              end
            end
          end

          if @expected.send(t).has_key?(name)
            details[:expected] = @expected.send(t)[name]
          end
          details
        end
 
        private
        def snap_db
          t = Time.now.utc
          @snapshot = "Database upgrade to #{@db_version} automatic pre-upgrade snapshot at #{t} -- #{::Rhubarb::Util::timestamp.to_s(16)}"
          log.info "Creating snapshot named '#{@snapshot}'"
          if @store.makeSnapshot(@snapshot) == nil
            raise RuntimeError.new("Failed to create snapshot")
          end
        end

        def get_db_ver_from_store
          default_ver = "1.4"
          db_ver = default_ver
          db_obj = @store.getFeature("BaseDBVersion") rescue nil
          if db_obj != nil
            ver = (db_obj.params["BaseDBVersion"].to_s rescue default_ver)
            if ver != ""
              db_ver = ver
            end
          end
          db_ver
        end

        def valid_db_version
          ver = get_db_ver_from_store
          log.debug("Store DB version: #{ver.inspect}")
          log.debug("Patch version: #{@db_version.inspect}")
          temp = ver.split('.')
          db_major = temp[0].delete("v").to_i
          db_minor = temp[1].to_i
          temp = @db_version.to_s.split('.')
          patch_major = temp[0].to_i
          patch_minor = temp[1].to_i

          (patch_major > db_major) || ((patch_major <= db_major) && (patch_minor > db_minor))
        end

        def update_entities
          @entities.each do |type|
            type = type.intern
            otype = obj_type(type)
            @updates.send(type).keys.each do |name|
              added = false
              if @store.send("check#{otype}Validity", [name]) != []
                log.info "Adding #{otype} '#{name}'"
                if type == :groups
                  obj = @store.send("addExplicitGroup", name)
                else
                  method = Mrg::Grid::Config::Store.instance_methods(false).grep(/^add#{type.to_s.slice(0,5).capitalize}/)
                  obj = @store.send(method.to_s, name)
                end
                added = true
              else
                obj = get_entity(type, name)
              end

              if obj == nil
                raise RuntimeError.new("Failed to retrieve #{otype} '#{name}'")
              end

              if ((added == false) && (@expected.send(type).has_key?(name))) && (not @force)
                verify_entity(obj, type, name)
              end

              log.info "Updating #{otype} '#{name}'"
              commands = @updates.send(type)[name].keys
              if commands.include?("setMustChange")
                commands.delete("setMustChange")
                commands.insert(0, "setMustChange")
              end
              commands.each do |set|
                validate_accessor(otype, set)
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
            type = type.intern
            otype = obj_type(type)
            @expected.send(type).keys.each do |name|
              if (not @updates.send(type).has_key?(name)) && (name.index("+++") == nil)
                verify_entity(get_entity(type, name), type, name)
                log.info "Removing #{otype} '#{name}'"
                method = Mrg::Grid::Config::Store.instance_methods(false).grep(/^remove#{type.to_s.slice(0,5).capitalize}/)
                @store.send(method.to_s, name)
              end
            end
          end

          create_relationships
        end

        def verify_entity(obj, type, name)
          otype = obj_type(type)
          log.info "Verifying #{otype} '#{name}'"
          @expected.send(type)[name].keys.each do |get|
            log.debug "Verifying #{otype} '#{name}##{get}'"
            validate_accessor(otype, get)
            current_val = obj.send(get)
            if (name == "BaseDBVersion") && (current_val.has_key?("BaseDBVersion"))
              current_val["BaseDBVersion"].delete!("v")
            end
            if type == :features and get == "params"
              log.debug "Generating params using default values"
              default_params = obj.param_meta.select {|k,v| v["uses_default"] == true || v["uses_default"] == 1}.map {|pair| pair[0]}
              log.debug "Params using default values: #{default_params.inspect}"
              default_params.each {|dp_key| current_val[dp_key] = 0}
            end
            expected_val = @expected.send(type)[name][get]
            if (name == "BaseDBVersion") && (expected_val.has_key?("BaseDBVersion"))
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
              raise RuntimeError.new("#{otype} '#{name}' has a current value of #{current_adj.inspect} but expected #{expected_adj.inspect}")
            end
          end
        end

        def get_entity(type, name)
          otype = obj_type(type)
          log.info "Retrieving #{otype} '#{name}'"
          if type == :groups
            obj = @store.send("getGroupByName", name)
          else
            method = Mrg::Grid::Config::Store.instance_methods(false).grep(/^get#{type.to_s.slice(0,5).capitalize}/)
            obj = @store.send(method.to_s, name)
          end
          obj
        end

        def validate_accessor(type, name)
          log.debug "Validating method #{type}##{name}"
          if name.class == String
            sym_n = name.intern
          else
            sym_n = name
          end
          if type.class == String
            sym_t = type.intern
          else
            sym_t = type
          end
          if not @valid_methods[type].include?(sym_n)
            raise RuntimeError.new("#{name} is an invalid object accessor")
          end
        end
      end
    end
  end  
end
