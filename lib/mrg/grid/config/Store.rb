# Store:  QMF wallaby store entity
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
require 'mrg/grid/config-proxies'

module Mrg
  module Grid
    module Config
      class Store
        include ::SPQR::Manageable

        qmf_package_name 'mrg.grid.config'
        qmf_class_name 'Store'

        def Store.find_by_id(u)
          @singleton ||= Store.new
        end

        def Store.find_all
          @singleton ||= Store.new
          [@singleton]
        end

        ### Property method declarations
        # property APIVersionNumber uint32 The version of the API the store supports
        attr_accessor :apiVersionNumber
        qmf_property :apiVersionNumber, :uint32, :desc=>"The version of the API the store supports", :index=>false
        ### Schema method declarations
        
        def getDefaultGroup
          return Group.DEFAULT_GROUP
        end
        
        expose :getDefaultGroup do |args|
          args.declare :obj, :objId, :out, {}
        end
        
        # getGroup 
        # * query (map/I)
        #   A map(queryType, value) that defines the group desired. The queryType can be either 'ID' or 'Name'. 'ID' queryTypes will search for a group with the ID defined in value. 'Name' queryTypes will search for a group with the name defined in value.
        # * obj (objId/O)
        def getGroup(query)
          qentries = query.entries
          fail(Errors.make(Errors::BAD_QUERY, Errors::GROUP), "Invalid group query #{query.inspect}") if qentries.size != 1
          qkind, qkey = query.entries.pop
          qkind = qkind.upcase
          
          case qkind
          when "ID"
            grp = Group.find(qkey)
            fail(Errors.make(Errors::NONEXISTENT_ENTITY, Errors::GROUP), "Group ID #{qkey} not found") unless grp
            return grp
          when "NAME"
            grp = Group.find_first_by_name(qkey)
            fail(Errors.make(Errors::NONEXISTENT_ENTITY, Errors::GROUP), "Group named #{qkey} not found") unless grp
            return grp
          else fail(Errors.make(Errors::BAD_QUERY, Errors::GROUP), "Invalid group query kind #{qkind}")
          end
        end
        
        expose :getGroup do |args|
          args.declare :obj, :objId, :out, {}
          args.declare :query, :map, :in, {}
        end

        def getGroupByName(name)
          getGroup({"NAME"=>name})
        end
        
        expose :getGroupByName do |args|
          args.declare :name, :sstr, :in, {}
          args.declare :obj, :objId, :out, {}
        end
        
        # addExplicitGroup 
        # * name (sstr/I)
        # * obj (objId/O)
        def addExplicitGroup(name)
          # Print values of input parameters
          log.debug "addExplicitGroup: name => #{name.inspect}"
          fail(Errors.make(Errors::NAME_ALREADY_IN_USE, Errors::GROUP), "Group name #{name} is already taken") if Group.find_first_by_name(name)
          fail(Errors.make(Errors::INVALID_NAME, Errors::GROUP), "Group name #{name} is invalid; group names may not start with '+++'") if name.slice(0,3) == "+++"
          Group.create(:name=>name)
        end
        
        expose :addExplicitGroup do |args|
          args.declare :obj, :objId, :out, {}
          args.declare :name, :sstr, :in, {}
        end
        
        # removeGroup 
        # * uid (uint32/I)
        def removeGroup(name)
          # Print values of input parameters
          log.debug "removeGroup: name => #{name.inspect}"
          group = Group.find_first_by_name(name)
          fail(Errors.make(Errors::NONEXISTENT_ENTITY, Errors::GROUP), "Group named #{name} not found") unless group
          group.delete
        end
        
        expose :removeGroup do |args|
          args.declare :name, :sstr, :in, {}
        end
        
        # getFeature 
        # * name (sstr/I)
        # * obj (objId/O)
        def getFeature(name)
          # Print values of input parameters
          log.debug "getFeature: name => #{name.inspect}"
          
          feature = Feature.find_first_by_name(name)
          fail(Errors.make(Errors::NONEXISTENT_ENTITY, Errors::FEATURE), "Feature named #{name} not found") unless feature
          return feature

        end
        
        expose :getFeature do |args|
          args.declare :obj, :objId, :out, {}
          args.declare :name, :sstr, :in, {}
        end
        
        # addFeature 
        # * name (sstr/I)
        # * obj (objId/O)
        def addFeature(name)
          # Print values of input parameters
          log.debug "addFeature: name => #{name.inspect}"
          fail(Errors.make(Errors::NAME_ALREADY_IN_USE, Errors::FEATURE), "Feature name #{name} is already taken") if Feature.find_first_by_name(name)
          return Feature.create(:name=>name)
        end
        
        expose :addFeature do |args|
          args.declare :obj, :objId, :out, {}
          args.declare :name, :sstr, :in, {}
        end
        
        # removeFeature 
        # * uid (uint32/I)
        def removeFeature(name)
          # Print values of input parameters
          log.debug "removeFeature: name => #{name.inspect}"
          feature = Feature.find_first_by_name(name)
          
          fail(Errors.make(Errors::NONEXISTENT_ENTITY, Errors::FEATURE), "Feature named #{name} does not exist") unless feature
          
          feature.delete
        end
        
        expose :removeFeature do |args|
          args.declare :name, :sstr, :in, {}
        end
        
        # activateConfiguration 
        # * explain (map/O)
        #   A map containing an explanation of why the configuration isn't valid, or
        #   an empty map if the configuration was successfully pushed out
        # * warnings (map/O)
        #   A map whose keys represent a set of warnings encountered in configuration activation
        
        def activateConfiguration()
          validate_and_activate
        end
        
        expose :activateConfiguration do |args|
          args.declare :explain, :map, :out, {}
          args.declare :warnings, :list, :out, {}
        end
        
        def validateConfiguration
          validate_and_activate(true)
        end
        
        expose :validateConfiguration do |args|
          args.declare :explain, :map, :out, {}
          args.declare :warnings, :list, :out, {}
        end
        
        # addNode 
        # * name (sstr/I)
        # * obj (objId/O)
        def addNode(name)
          # Print values of input parameters
          log.debug "addNode: name => #{name.inspect}"

          n = Node.find_first_by_name(name)
          
          if n
            # Since this node already exists but is being explicitly added now, ensure that it is marked as "provisioned"
            n.provisioned = true
          else
            # Return a newly-created node 
            n = Node.create(:name => name, :last_checkin => 0, :last_updated_version=>0)
          end
          
          # Mark the new node as "dirty" so it will get an updated configuration
          DirtyElement.dirty_node(n)
          
          # Return the appropriate node after ensuring that its identity group is initialized
          n.getIdentityGroup
          n
        end
        
        expose :addNode do |args|
          args.declare :obj, :objId, :out, {}
          args.declare :name, :sstr, :in, {}
        end

        # getNode 
        # * name (sstr/I)
        # * obj (objId/O)
        def getNode(name)
          # Print values of input parameters
          log.debug "getNode: name => #{name.inspect}"

          # Return the node with the given name
          n = Node.find_first_by_name(name) 
          unless n
            n = Node.create(:name=>name, :provisioned=>false, :last_checkin=>0, :last_updated_version=>0)
            
            # Mark the new node as "dirty" so it will get an updated configuration
            DirtyElement.dirty_node(n)
          end
          
          n
        end
        
        expose :getNode do |args|
          args.declare :obj, :objId, :out, {}
          args.declare :name, :sstr, :in, {}
        end
        
        # removeNode 
        # * name (sstr/I)
        def removeNode(name)
          # Print values of input parameters
          log.debug "removeNode: name => #{name.inspect}"

          # Actually remove the node
          node = Node.find_first_by_name(name)
          
          if node
            node.idgroup.delete if node.idgroup
            node.delete
          else
            fail(7, "Failed to remove nonexistent node #{name}")
          end
        end
        
        expose :removeNode do |args|
          args.declare :name, :sstr, :in, {}
        end
        
        # getParam 
        # * name (sstr/I)
        # * obj (objId/O)
        #   A reference to the parameter object that matches the name supplied
        def getParam(name)
          # Print values of input parameters
          log.debug "getParam: name => #{name.inspect}"

          param = Parameter.find_first_by_name(name)
          fail(Errors.make(Errors::NONEXISTENT_ENTITY, Errors::PARAMETER), "Parameter named #{name} not found") unless param

          return param
        end
        
        expose :getParam do |args|
          args.declare :obj, :objId, :out, {}
          args.declare :name, :sstr, :in, {}
        end
        
        # addParam 
        # * name (sstr/I)
        # * obj (objId/O)
        #   A reference to the newly added parameter object
        def addParam(name)
          # Print values of input parameters
          log.debug "addParam: name => #{name.inspect}"
           fail(Errors.make(Errors::NAME_ALREADY_IN_USE, Errors::PARAMETER), "Parameter name #{name} is already taken") if Parameter.find_first_by_name(name)
          # Return value
          return Parameter.create(:name => name)
        end
        
        expose :addParam do |args|
          args.declare :obj, :objId, :out, {}
          args.declare :name, :sstr, :in, {}
        end
        
        # getSubsys 
        # * name (sstr/I)
        # * obj (objId/O)
        #   A reference to the subsystem object that matches the name supplied
        def getSubsys(name)
          # Print values of input parameters
          log.debug "getSubsys: name => #{name.inspect}"

          return Subsystem.find_first_by_name(name)
        end

        expose :getSubsys do |args|
          args.declare :obj, :objId, :out, {}
          args.declare :name, :sstr, :in, {}
        end

        # addSubsys 
        # * name (sstr/I)
        # * obj (objId/O)
        #   A reference to the newly added subsystem object
        def addSubsys(name)
          # Print values of input parameters
          log.debug "addSubsys: name => #{name.inspect}"
           fail(Errors.make(Errors::NAME_ALREADY_IN_USE, Errors::SUBSYSTEM), "Subsystem name #{name} is already taken") if Subsystem.find_first_by_name(name)
          # Return value
          return Subsystem.create(:name => name)
        end

        expose :addSubsys do |args|
          args.declare :obj, :objId, :out, {}
          args.declare :name, :sstr, :in, {}
        end
        
        
        # removeParam 
        # * name (sstr/I)
        def removeParam(name)
          # Print values of input parameters
          log.debug "removeParam: name => #{name.inspect}"
          
          param = Parameter.find_first_by_name(name)
          fail(7, "Parameter named #{name} not found") unless param

          param.delete
        end
        
        expose :removeParam do |args|
          args.declare :name, :sstr, :in, {}
        end

        # removeSubsys 
        # * name (sstr/I)
        def removeSubsys(name)
          # Print values of input parameters
          log.debug "removeSubsys: name => #{name.inspect}"
          Subsystem.find_first_by_name(name).delete
        end

        expose :removeSubsys do |args|
          args.declare :name, :sstr, :in, {}
        end
        
        def storeinit(kwargs=nil)
          kwargs ||= {}
          if kwargs.keys.map {|k| k.upcase}.include? "RESETDB"
            clear_db
          end
          
          Group.DEFAULT_GROUP
          nil
        end
        
        expose :storeinit do |args|
          args.declare :options, :map, :in, {}
        end
        
        # <method name="makeSnapshot">
        #    <arg name="name" dir="I" type="sstr"
        #         desc="A name for this configuration.  A blank name will result
        #               in the store creating a name"/>
        # </method>
        
        def makeSnapshot(name)
          tm = Time.now.utc
          name = "Automatically generated snapshot at #{tm} -- #{((tm.tv_sec * 1000000) + tm.tv_usec).to_s(16)}" if name.size == 0
          fail(42, "Snapshot name #{name} already taken") if Snapshot.find_first_by_name(name)
          result = Snapshot.create(:name=>name)
          snaptext = ::Mrg::Grid::SerializedConfigs::ConfigSerializer.new(self, false).serialize.to_yaml
          result.snaptext = snaptext
        end
        
        expose :makeSnapshot do |args|
          args.declare :name, :sstr, :in, :desc=>"A name for this configuration.  A blank name will result in the store creating a name"
        end
        
        def loadSnapshot(name)
          snap = Snapshot.find_first_by_name(name)
          
          fail(Errors.make(Errors::NONEXISTENT_ENTITY, Errors::SNAPSHOT), "Invalid snapshot name #{name}") unless snap
          snaptext = snap.snaptext
          
          storeinit("RESETDB"=>true)
          
          ::Mrg::Grid::SerializedConfigs::ConfigLoader.log = log
          
          ::Rhubarb::Persistence::db.transaction do |the_db|
            ::Mrg::Grid::SerializedConfigs::ConfigLoader.new(self, snaptext).load
          end
          
        end
        
        expose :loadSnapshot do |args|
          args.declare :name, :sstr, :in, :desc=>"A name for the configuration to load."
        end
        
        def removeSnapshot(name)
          Snapshot.find_first_by_name(name).delete
        end
        
        expose :removeSnapshot do |args|
          args.declare :name, :sstr, :in, :desc=>"A name for the configuration to load."
        end

        def getMustChangeParams
          Parameter.s_that_must_change
        end
        
        expose :getMustChangeParams do |args|
          args.declare :params, :map, :out, :desc=>"Parameters that must change; a map from names to default values"
        end
        
        [Feature, Group, Node, Parameter, Subsystem].each do |klass|
          define_method "check#{klass.name.split("::").pop}Validity".to_sym do |fset|
            log.debug "check#{klass.name.split("::").pop}Validity called:  set is #{fset}"
            entities = fset.sort.uniq
            klass.select_invalid(entities)
          end
          
          expose "check#{klass.name.split("::").pop}Validity".to_sym do |args|
            args.declare :set, :list, :in, :desc=>"A set of #{klass.name} names to check for validity"
            args.declare "invalid#{klass.name.split("::").pop}s".to_sym, :list, :out, :desc=>"A (possibly-empty) set consisting of all of the #{klass.name} names from the input set that do not correspond to valid #{klass.name}s"
          end
        end
        
        
        def event_class
          @event_class ||= init_event_class
        end
        
        def new_config_event(nodes, version)
          log.debug "ENTERING new_config_event with app == #{app.inspect}; if you don't see a STILL HERE message soon, we're not raising an event"
          return nil unless (Store.respond_to?(:app) && app)
          log.debug "STILL HERE in scenic new_config_event"
          
          map = Hash[*nodes.zip([version] * nodes.length).flatten]
          event = Qmf::QmfEvent.new(event_class)
          log.debug "event is #{event.inspect}"
          event.nodelist = map
          event.nodelist_str = map.keys.join(",")
          log.debug "event.nodelist is #{event.nodelist.inspect}"
          app.agent.raise_event(event)
        end
        
        private
        def app
          Store.app rescue nil
        end
        
        def clear_db
          MAIN_DB_TABLES.each do |table|
            table.delete_all rescue table.find_all.each {|row| row.delete}
          end
        end
        
        def init_event_class
          event_class = Qmf::SchemaEventClass.new("mrg.grid.config", "NewConfigEvent", Qmf::SEV_ALERT)
          event_class.add_argument(Qmf::SchemaArgument.new("nodelist", Qmf::TYPE_MAP))
          event_class.add_argument(Qmf::SchemaArgument.new("nodelist_str", Qmf::TYPE_LSTR))
          app.agent.register_class(event_class)
          event_class
        end

        def validate_and_activate(validate_only=false)
          result = nil
          unless ::Rhubarb::Persistence::db.transaction_active?
            ::Rhubarb::Persistence::db.transaction do |the_db|
              result = _validate_and_activate(validate_only)
            end
          else
            result = _validate_and_activate(validate_only)
          end
          
          result
        end
        
        def _validate_and_activate(validate_only=false)
          dirty_nodes = Node.get_dirty_nodes
          this_version = ::Rhubarb::Util::timestamp
          default_group_only = (dirty_nodes.size == 0)
          warnings = []
          
          if default_group_only
            log.warn "Attempting to activate a configuration with no nodes; will simply check the configuration of the default group"
            dirty_nodes << Group.DEFAULT_GROUP
            warnings << "No nodes in configuration; only tested default group"
          end
          
          results = Hash[*dirty_nodes.map {|node| node.validate}.reject {|result| result == true}.flatten]
          
          if validate_only || default_group_only || results.keys.size > 0
            return [results, warnings]
          end
                    
          dirty_nodes.each {|dn| dn.last_updated_version = this_version }
          
          DirtyElement.delete_all
          
          new_config_event(dirty_nodes.map {|dn| dn.name}, this_version)
          
          [results, warnings]
        end
        
      end
    end
  end
end
