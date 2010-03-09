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
        
        def GetDefaultGroup
          return Group.DEFAULT_GROUP
        end
        
        expose :GetDefaultGroup do |args|
          args.declare :obj, :objId, :out, {}
        end
        
        # GetGroup 
        # * query (map/I)
        #   A map(queryType, value) that defines the group desired. The queryType can be either 'ID' or 'Name'. 'ID' queryTypes will search for a group with the ID defined in value. 'Name' queryTypes will search for a group with the name defined in value.
        # * obj (objId/O)
        def GetGroup(query)
          qentries = query.entries
          fail(7, "Invalid group query #{query.inspect}") if qentries.size != 1
          qkind, qkey = query.entries.pop
          qkind = qkind.upcase
          
          case qkind
          when "ID"
            grp = Group.find(qkey)
            fail(7, "Group ID #{qkey} not found") unless grp
            return grp
          when "NAME"
            grp = Group.find_first_by_name(qkey)
            fail(7, "Group named #{qkey} not found") unless grp
            return grp
          else fail(7, "Invalid group query kind #{qkind}")
          end
        end
        
        expose :GetGroup do |args|
          args.declare :obj, :objId, :out, {}
          args.declare :query, :map, :in, {}
        end

        def GetGroupByName(name)
          GetGroup({"NAME"=>name})
        end
        
        expose :GetGroupByName do |args|
          args.declare :name, :sstr, :in, {}
          args.declare :obj, :objId, :out, {}
        end
        
        # AddExplicitGroup 
        # * name (sstr/I)
        # * obj (objId/O)
        def AddExplicitGroup(name)
          # Print values of input parameters
          log.debug "AddExplicitGroup: name => #{name.inspect}"
          fail(42, "Group name #{name} is already taken") if Group.find_first_by_name(name)
          fail(42, "Group name #{name} is invalid; group names may not start with '+++'") if name.slice(0,3) == "+++"
          Group.create(:name=>name)
        end
        
        expose :AddExplicitGroup do |args|
          args.declare :obj, :objId, :out, {}
          args.declare :name, :sstr, :in, {}
        end
        
        # RemoveGroup 
        # * uid (uint32/I)
        def RemoveGroup(name)
          # Print values of input parameters
          log.debug "RemoveGroup: name => #{name.inspect}"
          group = Group.find_first_by_name(name)
          fail(7, "Group named #{name} not found") unless group
          group.delete
        end
        
        expose :RemoveGroup do |args|
          args.declare :name, :sstr, :in, {}
        end
        
        # GetFeature 
        # * name (sstr/I)
        # * obj (objId/O)
        def GetFeature(name)
          # Print values of input parameters
          log.debug "GetFeature: name => #{name.inspect}"
          
          feature = Feature.find_first_by_name(name)
          fail(7, "Feature named #{name} not found") unless feature
          return feature

        end
        
        expose :GetFeature do |args|
          args.declare :obj, :objId, :out, {}
          args.declare :name, :sstr, :in, {}
        end
        
        # AddFeature 
        # * name (sstr/I)
        # * obj (objId/O)
        def AddFeature(name)
          # Print values of input parameters
          log.debug "AddFeature: name => #{name.inspect}"
          fail(42, "Feature name #{name} is already taken") if Feature.find_first_by_name(name)
          return Feature.create(:name=>name)
        end
        
        expose :AddFeature do |args|
          args.declare :obj, :objId, :out, {}
          args.declare :name, :sstr, :in, {}
        end
        
        # RemoveFeature 
        # * uid (uint32/I)
        def RemoveFeature(name)
          # Print values of input parameters
          log.debug "RemoveFeature: name => #{name.inspect}"
          feature = Feature.find_first_by_name(name)
          
          fail(7, "Feature named #{name} does not exist") unless feature
          
          feature.delete
        end
        
        expose :RemoveFeature do |args|
          args.declare :name, :sstr, :in, {}
        end
        
        # ActivateConfiguration 
        # * explain (map/O)
        #   A map containing an explanation of why the configuration isn't valid, or
        #   an empty map if the configuration was successfully pushed out
        
        def ActivateConfiguration()
          dirty_nodes = Node.get_dirty_nodes
          this_version = ::Rhubarb::Util::timestamp
          
          results = Hash[*dirty_nodes.map {|node| node.validate}.reject {|result| result == true}.flatten]
          
          if results.keys.size > 0
            return results
          end
                    
          dirty_nodes.each {|dn| dn.last_updated_version = this_version }
          
          DirtyElement.delete_all
          
          new_config_event(dirty_nodes.map {|dn| dn.name}, this_version)
          
          results
        end
        
        expose :ActivateConfiguration do |args|
          args.declare :explain, :map, :out, {}
        end
        
        # AddNode 
        # * name (sstr/I)
        # * obj (objId/O)
        def AddNode(name)
          # Print values of input parameters
          log.debug "AddNode: name => #{name.inspect}"

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
          n.GetIdentityGroup
          n
        end
        
        expose :AddNode do |args|
          args.declare :obj, :objId, :out, {}
          args.declare :name, :sstr, :in, {}
        end

        # GetNode 
        # * name (sstr/I)
        # * obj (objId/O)
        def GetNode(name)
          # Print values of input parameters
          log.debug "GetNode: name => #{name.inspect}"

          # Return the node with the given name
          n = Node.find_first_by_name(name) 
          unless n
            n = Node.create(:name=>name, :provisioned=>false, :last_checkin=>0, :last_updated_version=>0)
            
            # Mark the new node as "dirty" so it will get an updated configuration
            DirtyElement.dirty_node(n)
          end
          
          n
        end
        
        expose :GetNode do |args|
          args.declare :obj, :objId, :out, {}
          args.declare :name, :sstr, :in, {}
        end
        
        # RemoveNode 
        # * name (sstr/I)
        def RemoveNode(name)
          # Print values of input parameters
          log.debug "RemoveNode: name => #{name.inspect}"

          # Actually remove the node
          node = Node.find_first_by_name(name)
          
          if node
            node.idgroup.delete if node.idgroup
            node.delete
          else
            fail(7, "Failed to remove nonexistent node #{name}")
          end
        end
        
        expose :RemoveNode do |args|
          args.declare :name, :sstr, :in, {}
        end
        
        # GetParam 
        # * name (sstr/I)
        # * obj (objId/O)
        #   A reference to the parameter object that matches the name supplied
        def GetParam(name)
          # Print values of input parameters
          log.debug "GetParam: name => #{name.inspect}"

          param = Parameter.find_first_by_name(name)
          fail(7, "Parameter named #{name} not found") unless param

          return param
        end
        
        expose :GetParam do |args|
          args.declare :obj, :objId, :out, {}
          args.declare :name, :sstr, :in, {}
        end
        
        # AddParam 
        # * name (sstr/I)
        # * obj (objId/O)
        #   A reference to the newly added parameter object
        def AddParam(name)
          # Print values of input parameters
          log.debug "AddParam: name => #{name.inspect}"
           fail(42, "Parameter name #{name} is already taken") if Parameter.find_first_by_name(name)
          # Return value
          return Parameter.create(:name => name)
        end
        
        expose :AddParam do |args|
          args.declare :obj, :objId, :out, {}
          args.declare :name, :sstr, :in, {}
        end
        
        # GetSubsys 
        # * name (sstr/I)
        # * obj (objId/O)
        #   A reference to the subsystem object that matches the name supplied
        def GetSubsys(name)
          # Print values of input parameters
          log.debug "GetSubsys: name => #{name.inspect}"

          return Subsystem.find_first_by_name(name)
        end

        expose :GetSubsys do |args|
          args.declare :obj, :objId, :out, {}
          args.declare :name, :sstr, :in, {}
        end

        # AddSubsys 
        # * name (sstr/I)
        # * obj (objId/O)
        #   A reference to the newly added subsystem object
        def AddSubsys(name)
          # Print values of input parameters
          log.debug "AddSubsys: name => #{name.inspect}"
           fail(42, "Subsystem name #{name} is already taken") if Subsystem.find_first_by_name(name)
          # Return value
          return Subsystem.create(:name => name)
        end

        expose :AddSubsys do |args|
          args.declare :obj, :objId, :out, {}
          args.declare :name, :sstr, :in, {}
        end
        
        
        # RemoveParam 
        # * name (sstr/I)
        def RemoveParam(name)
          # Print values of input parameters
          log.debug "RemoveParam: name => #{name.inspect}"
          
          param = Parameter.find_first_by_name(name)
          fail(7, "Parameter named #{name} not found") unless param

          param.delete
        end
        
        expose :RemoveParam do |args|
          args.declare :name, :sstr, :in, {}
        end

        # RemoveSubsys 
        # * name (sstr/I)
        def RemoveSubsys(name)
          # Print values of input parameters
          log.debug "RemoveSubsys: name => #{name.inspect}"
          Subsystem.find_first_by_name(name).delete
        end

        expose :RemoveSubsys do |args|
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
        
        # <method name="MakeSnapshot">
        #    <arg name="name" dir="I" type="sstr"
        #         desc="A name for this configuration.  A blank name will result
        #               in the store creating a name"/>
        # </method>
        
        def MakeSnapshot(name)
          tm = Time.now.utc
          name = "Automatically generated snapshot at #{tm} -- #{((tm.tv_sec * 1000000) + tm.tv_usec).to_s(16)}" if name.size == 0
          fail(42, "Snapshot name #{name} already taken") if Snapshot.find_first_by_name(name)
          result = Snapshot.create(:name=>name)
          snaptext = ::Mrg::Grid::SerializedConfigs::ConfigSerializer.new(self, false).serialize.to_yaml
          result.snaptext = snaptext
        end
        
        expose :MakeSnapshot do |args|
          args.declare :name, :sstr, :in, :desc=>"A name for this configuration.  A blank name will result in the store creating a name"
        end
        
        def LoadSnapshot(name)
          snap = Snapshot.find_first_by_name(name)
          
          fail(31, "Invalid snapshot name #{name}") unless snap
          snaptext = snap.snaptext
          
          storeinit("RESETDB"=>true)
          
          ::Mrg::Grid::SerializedConfigs::ConfigLoader.log = log
          
          ::Rhubarb::Persistence::db.transaction do |the_db|
            ::Mrg::Grid::SerializedConfigs::ConfigLoader.new(self, snaptext).load
          end
          
        end
        
        expose :LoadSnapshot do |args|
          args.declare :name, :sstr, :in, :desc=>"A name for the configuration to load."
        end
        
        def RemoveSnapshot(name)
          Snapshot.find_first_by_name(name).delete
        end
        
        expose :RemoveSnapshot do |args|
          args.declare :name, :sstr, :in, :desc=>"A name for the configuration to load."
        end

        def GetMustChangeParams
          Parameter.s_that_must_change
        end
        
        expose :GetMustChangeParams do |args|
          args.declare :params, :map, :out, :desc=>"Parameters that must change; a map from names to default values"
        end
        
        [Feature, Group, Node, Parameter, Subsystem].each do |klass|
          define_method "check#{klass.name}Validity".to_sym do |fakeset|
            log.debug "check#{klass.name}Validity called:  set is #{fakeset}"
            entities = fakeset.keys.sort.uniq
            FakeSet[*klass.select_invalid(entities)]
          end
          
          expose "check#{klass.name}Validity".to_sym do |args|
            args.declare :set, :map, :in, :desc=>"A set of #{klass.name} names to check for validity"
            args.declare "invalid#{klass.name}s".to_sym, :map, :out, :desc=>"A (possibly-empty) set consisting of all of the #{klass.name} names from the input set that do not correspond to valid #{klass.name}s"
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
        
      end
    end
  end
end
