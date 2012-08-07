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
require 'mrg/grid/util/quiescent'
require 'socket'

require 'mrg/grid/config/auth'

module Mrg
  module Grid
    module Config
      module QmfV1Kludges
        MAX_ARG_SIZE = 65535          # QMFv1 maximum argument size
        MAX_SIZE_CUSHION = (4096 * 4) # 4 pages is pretty arbitrary
        OBJECT_OVERHEAD = 32
      end
      
      class NodeUpdatedNotice
         include ::SPQR::Raiseable
         arg :nodes, :map, "A map whose keys are the node names that must update."
         arg :version, :uint64, "The version of the latest configuration for these nodes."
         qmf_class_name :NodeUpdatedNotice
         qmf_package_name "com.redhat.grid.config"
         qmf_severity :notice
      end
      
      class Store
        include ::SPQR::Manageable
        include QmfV1Kludges
        include ::Mrg::Grid::Util::Quiescent
        include ::Mrg::Grid::Config::Auth::ORIZING
        
        ENABLE_DEFAULT_GROUP = true
        quiescent :ENABLE_SKELETON_GROUP do
          result = ENV["WALLABY_ENABLE_SKELETON_GROUP"] && ENV["WALLABY_ENABLE_SKELETON_GROUP"] =~ /^[yt1]/i
          log.info "#{result ? "" : "not "}enabling the skeleton group; WALLABY_ENABLE_SKELETON_GROUP == '#{ENV['WALLABY_ENABLE_SKELETON_GROUP'].inspect}'"
          result
        end
        
        qmf_package_name 'com.redhat.grid.config'
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
        qmf_property :apiVersionNumber, :uint32, :desc=>"The version of the API the store supports", :index=>false
        def apiVersionNumber
          20101031
        end

        ### Property method declarations
        # property APIVersionNumber uint32 The version of the API the store supports
        qmf_property :apiMinorNumber, :uint32, :desc=>"The minor version (revision) of the API the store supports", :index=>false
        def apiMinorNumber
          6
        end

        qmf_property :host_and_pid, :list, :desc=>"A tuple consisting of the hostname and process ID, identifying where this wallaby agent is currently running.  (Introduced in 20101031.1)", :index=>false
        def host_and_pid
          [Socket.gethostname, Process.pid]
        end
        
        qmf_property :wallaby_version, :sstr, :desc=>"A string representation of the version of this wallaby agent.  (Introduced in API version 20101031.1)"
        def wallaby_version
          ::Mrg::Grid::Config::Version.as_string
        end

        ### Schema method declarations
        
        # sets Wallaby privileges for a given user
        def set_user_privs(username, privs, options=nil)
          options ||= {}
          
          # note that we authorize here to allow use of WALLABY_SECRET
          authorize_now(:ADMIN) unless authorized_via_secret(options["secret"])
          
          fail(Errors.make(Errors::BAD_ARGUMENT), "Invalid privilege level #{privs}") unless %w{READ WRITE ADMIN NONE}.include?(privs)
          
          role = (::Mrg::Grid::Config::Auth::Role.find_first_by_username(username) || ::Mrg::Grid::Config::Auth::Role.create(:username=>username, :privs=>::Mrg::Grid::Config::Auth::Priv::NONE))
          role.privs = ::Mrg::Grid::Config::Auth::Priv.const_get(privs)
          
          ::Mrg::Grid::Config::Auth::RoleCache.populate
          
          nil
        end
        
        expose :set_user_privs do |args|
          args.declare :username, :lstr, :in, "The username to set privileges for."
          args.declare :privs, :sstr, :in, "One of 'READ', 'WRITE', or 'ADMIN.'"
          args.declare :options, :map, :in, "Recognized options include 'secret', which is your installation's Wallaby secret."
        end

        # deletes role for a given user
        def del_user(username, options=nil)
          options ||= {}
          
          # note that we authorize here to allow use of WALLABY_SECRET
          authorize_now(:ADMIN) unless authorized_via_secret(options["secret"])
          
          role = ::Mrg::Grid::Config::Auth::Role.find_first_by_username(username)
          fail(Errors.make(Errors::BAD_ARGUMENT), "User #{username} does not exist in the Wallaby role database") unless role
          
          role.delete
          
          ::Mrg::Grid::Config::Auth::RoleCache.populate
          
          nil
        end
        
        expose :del_user do |args|
          args.declare :username, :lstr, :in, "The username to set privileges for."
          args.declare :options, :map, :in, "Recognized options include 'secret', which is your installation's Wallaby secret."
        end
        
        def users(options=nil)
          options ||= {}
          
          authorize_now(:READ) unless authorized_via_secret(options["secret"])
          
          ::Mrg::Grid::Config::Auth::Role.find_all.inject({}) do |acc, role|
            acc[role.username] = ::Mrg::Grid::Config::Auth::Priv.to_string(role.privs)
            acc
          end
        end

        expose :users do |args|
          args.declare :options, :map, :in, "Recognized options include 'secret', which is your installation's Wallaby secret."
          args.declare :roles, :map, :out, "Map of user names to privilege levels"
        end
        
        ["default", "skeleton"].each do |special_group|
          define_method "get#{special_group.capitalize}Group".to_sym do
            fail(Errors.make(Errors::NOT_IMPLEMENTED), "get#{special_group.capitalize}Group is not enabled") unless Store.const_get("ENABLE_#{special_group.upcase}_GROUP")
            return Group.send("#{special_group.upcase}_GROUP")
          end
        
          expose "get#{special_group.capitalize}Group".to_sym do |args|
            args.declare :obj, :objId, :out, "The object ID of the Group object corresponding to the #{special_group} group."
          end
          
          authorize_before "get#{special_group.capitalize}Group".to_sym, :READ
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
          args.declare :obj, :objId, :out, "The object ID of the Group object corresponding to the requested group."
          args.declare :query, :map, :in, "A map from a query type to a query parameter. The queryType can be either 'ID' or 'Name'. 'ID' queryTypes will search for a group with the ID supplied as a parameter. 'Name' queryTypes will search for a group with the name supplied as a parameter."
        end

        def getGroupByName(name)
          getGroup({"NAME"=>name})
        end
        
        authorize_before :getGroup, :READ
        
        expose :getGroupByName do |args|
          args.declare :name, :sstr, :in, "The name of the group to search for."
          args.declare :obj, :objId, :out, "The object ID of the Group object corresponding to the requested group."
        end
        
        authorize_before :getGroupByName, :READ
        
        # addExplicitGroup 
        # * name (sstr/I)
        # * obj (objId/O)
        def addExplicitGroup(name)
          # Print values of input parameters
          log.debug "addExplicitGroup: name => #{name.inspect}"
          fail(Errors.make(Errors::NAME_ALREADY_IN_USE, Errors::GROUP), "Group name #{name} is already taken") if Group.find_first_by_name(name)
          fail(Errors.make(Errors::INVALID_NAME, Errors::GROUP), "Group name #{name} is invalid; group names may not start with '+++'") if name.slice(0,3) == "+++"
          fail(Errors.make(Errors::INVALID_NAME, Errors::GROUP), "Group names cannot be empty") if name.size == 0
          Group.create(:name=>name)
        end
        
        expose :addExplicitGroup do |args|
          args.declare :obj, :objId, :out, "The object ID of the Group object corresponding to the newly-created group."
          args.declare :name, :sstr, :in, "The name of the newly-created group.  Names beginning with '+++' are reserved for internal use."
        end
        
        authorize_before :addExplicitGroup, :WRITE
        
        # removeGroup 
        # * uid (uint32/I)
        def removeGroup(name)
          # Print values of input parameters
          log.debug "removeGroup: name => #{name.inspect}"
          group = Group.find_first_by_name(name)
          fail(Errors.make(Errors::NONEXISTENT_ENTITY, Errors::GROUP), "Group named #{name} not found") unless group
          fail(Errors.make(Errors::BAD_COMMAND, Errors::GROUP), "Can't remove special group #{group.name}") if group.is_special
          group.db_membership.each {|n| DirtyElement.dirty_node(n) }
          group.delete
        end
        
        expose :removeGroup do |args|
          args.declare :name, :sstr, :in, "The name of the group to remove."
        end
        
        authorize_before :removeGroup, :WRITE
        
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
          args.declare :obj, :objId, :out, "The object ID of the Feature object corresponding to the requested feature."
          args.declare :name, :sstr, :in, "The name of the feature to search for."
        end
        
        authorize_before :getFeature, :READ
        
        # addFeature 
        # * name (sstr/I)
        # * obj (objId/O)
        def addFeature(name)
          # Print values of input parameters
          log.debug "addFeature: name => #{name.inspect}"
          fail(Errors.make(Errors::NAME_ALREADY_IN_USE, Errors::FEATURE), "Feature name #{name} is already taken") if Feature.find_first_by_name(name)
          fail(Errors.make(Errors::INVALID_NAME, Errors::FEATURE), "Feature names cannot be empty") if name.size == 0
          return Feature.create(:name=>name)
        end
        
        expose :addFeature do |args|
          args.declare :obj, :objId, :out, "The object ID of the newly-created Feature object."
          args.declare :name, :sstr, :in, "The name of the feature to create."
        end
        
        authorize_before :addFeature, :WRITE
        
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
          args.declare :name, :sstr, :in, "The name of the feature to remove."
        end

        authorize_before :removeFeature, :WRITE
        
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
          args.declare :explain, :map, :out, "A map containing an explanation of why the configuration isn't valid, or an empty map if the configuration was successfully activated."
          args.declare :warnings, :list, :out, "A set of warnings encountered during configuration activation."
        end

        authorize_before :activateConfiguration, :ACTIVATE
        
        def validateConfiguration
          validate_and_activate(true)
        end
        
        expose :validateConfiguration do |args|
          args.declare :explain, :map, :out, "A map containing an explanation of why the configuration isn't valid, or an empty map if the configuration was successfully activated."
          args.declare :warnings, :list, :out, "A set of warnings encountered during configuration activation."
        end
        
        authorize_before :validateConfiguration, :READ
        
        def affectedEntities(options=nil)
          options = {"failfast"=>nil}.merge(options || {})
          if options["failfast"]
            dg = DirtyElement.find_first_by_kind(DirtyElement.KIND_EVERYTHING)
            return [dg.to_pair] if dg
          end
          result = DirtyElement.find_all.map {|elt| elt.to_pair}
          bytes = OBJECT_OVERHEAD * 4 # XXX: this is conservative but perhaps unnecessarily so
          truncated_result = result.inject([]) do |acc, val|
            this_val_size = OBJECT_OVERHEAD * 3 + val[0].length + val[1].length
            if bytes + this_val_size < MAX_ARG_SIZE
              bytes += this_val_size
              acc << val
            else
              acc << ["OMITTED", "..."]
            end
          end
          truncated_result
        end
        
        expose :affectedEntities do |args|
          args.declare :options, :map, :in, "Valid options include 'failfast', which will return a single-element list if the default group or the whole store is dirty."
          args.declare :result, :list, :out, "A list of TYPE, NAME pairs indicating elements that have changed since the last activation and are due for validation and activation.  May be truncated due to communication limitations."
        end

        authorize_before :affectedEntities, :READ
        
        def affectedNodes(options=nil)
          options ||= {}
          result = Node.get_dirty_nodes
          bytes = OBJECT_OVERHEAD * 4 # XXX: this is conservative but perhaps unnecessarily so
          truncated_result = result.inject([]) do |acc, val|
            this_val_size = OBJECT_OVERHEAD + val.name.length
            if bytes + this_val_size < MAX_ARG_SIZE
              bytes += this_val_size
              acc << val
            else
              acc << "..."
            end
          end
          truncated_result
        end
        
        expose :affectedNodes do |args|
          args.declare :options, :map, :in, "No options are yet supported."
          args.declare :result, :list, :out, "A list of nodes that are due for validation and activation.  May be truncated due to communication limitations."
        end

        authorize_before :affectedNodes, :READ        
        
        # addNode 
        # * name (sstr/I)
        # * obj (objId/O)
        def addNode(name, options=nil)
          # Print values of input parameters
          log.debug "addNode: name => #{name.inspect}; options => #{options.inspect}"
          options ||= {}

          n = Node.find_first_by_name(name)
          
          if n
            # Since this node already exists but is being explicitly added now, ensure that it is marked as "provisioned"
            n.provisioned = true
          else
            # Return a newly-created node 
            n = createNode(name, true, options)
          end
          
          # Mark the new node as "dirty" so it will get an updated configuration
          DirtyElement.dirty_node(n)
          
          # Return the appropriate node after ensuring that its identity group is initialized
          n.identity_group
          n
        end

        alias addNodeWithOptions addNode

        expose :addNodeWithOptions do |args|
          args.declare :obj, :objId, :out, "The object ID of the newly-created Node object."
          args.declare :name, :sstr, :in, "The name of the node to create."
          args.declare :options, :map, :in, "Optional arguments. (Introduced in 20101031.2)"
        end
        
        expose :addNode do |args|
          args.declare :obj, :objId, :out, "The object ID of the newly-created Node object."
          args.declare :name, :sstr, :in, "The name of the node to create."
        end

        # XXX:  perhaps worth considering whether addNode and getNode demand WRITE access 
        # or READ access (since adding a node doesn't affect config but getting a node can 
        # result in node creation)
        authorize_before :addNode, :WRITE
        authorize_before :addNodeWithOptions, :WRITE

        # getNode 
        # * name (sstr/I)
        # * obj (objId/O)
        def getNode(name)
          # Print values of input parameters
          log.debug "getNode: name => #{name.inspect}"

          # Return the node with the given name
          n = Node.find_first_by_name(name) 
          unless n
            n = createNode(name, false)
            
            # Mark the new node as "dirty" so it will get an updated configuration
            DirtyElement.dirty_node(n)
          end
          
          n
        end
        
        expose :getNode do |args|
          args.declare :obj, :objId, :out, "The object ID of the retrieved Node object."
          args.declare :name, :sstr, :in, "The name of the node to find.  If no node exists with this name, the store will create an unprovisioned node with the given name."
        end

        authorize_before :getNode, :READ
        
        def createNode(name, is_provisioned=true, options=nil)
          options ||= {}
          fail(Errors.make(Errors::INVALID_NAME, Errors::NODE), "Node name #{name} is invalid; node names may not start with '+++'") if name.slice(0,3) == "+++"
          fail(Errors.make(Errors::INVALID_NAME, Errors::NODE), "Node names cannot be empty") if name.size == 0

          seek_version = options["seek_versioned_config"]
          seek_version = (seek_version && ConfigVersion.hasVersionedNodeConfig(name, seek_version)) || nil

          n = Node.create(:name=>name, :provisioned=>is_provisioned, :last_checkin=>0, :last_updated_version=>seek_version || 0)

          # add to the skeleton group
          n.modifyMemberships("ADD", [Group::SKELETON_GROUP_NAME], {}) if Store::ENABLE_SKELETON_GROUP

          # XXX:  this is almost certainly not the right place to do this (copying default config over for newly-created nodes)
          n.last_updated_version = seek_version || ConfigVersion.makeInitialConfig(name)
          n
        end
        
        # removeNode 
        # * name (sstr/I)
        def removeNode(name)
          # Print values of input parameters
          log.debug "removeNode: name => #{name.inspect}"

          # Actually remove the node
          node = Node.find_first_by_name(name)
          
          # Remove any versioned configurations for this node
          VersionedNode[name].delete
          
          if node
            node.idgroup.delete if node.idgroup
            node.delete
          else
            fail(7, "Failed to remove nonexistent node #{name}")
          end
        end
        
        expose :removeNode do |args|
          args.declare :name, :sstr, :in, "The name of the node to remove."
        end
        
        authorize_before :removeNode, :WRITE
        
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
          args.declare :obj, :objId, :out, "The object ID of the requested Parameter object."
          args.declare :name, :sstr, :in, "The name of the parameter to find."
        end
        
        authorize_before :getParam, :READ
        
        # addParam 
        # * name (sstr/I)
        # * obj (objId/O)
        #   A reference to the newly added parameter object
        def addParam(name)
          # Print values of input parameters
          log.debug "addParam: name => #{name.inspect}"
          
           fail(Errors.make(Errors::NAME_ALREADY_IN_USE, Errors::PARAMETER), "Parameter name #{name} is already taken") if Parameter.find_first_by_name(name)
          fail(Errors.make(Errors::INVALID_NAME, Errors::PARAMETER), "Parameter names cannot be empty") if name.size == 0

          # Return value
          return Parameter.create(:name => name)
        end
        
        expose :addParam do |args|
          args.declare :obj, :objId, :out, "The object ID of the newly-created Parameter object."
          args.declare :name, :sstr, :in, "The name of the parameter to create."
        end
        
        authorize_before :addParam, :WRITE

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
          args.declare :obj, :objId, :out, "The object ID of the requested Subsystem object."
          args.declare :name, :sstr, :in, "The name of the subsystem to find."
        end

        authorize_before :getSubsys, :READ

        # addSubsys 
        # * name (sstr/I)
        # * obj (objId/O)
        #   A reference to the newly added subsystem object
        def addSubsys(name)
          # Print values of input parameters
          log.debug "addSubsys: name => #{name.inspect}"
           fail(Errors.make(Errors::NAME_ALREADY_IN_USE, Errors::SUBSYSTEM), "Subsystem name #{name} is already taken") if Subsystem.find_first_by_name(name)
          fail(Errors.make(Errors::INVALID_NAME, Errors::SUBSYSTEM), "Subsystem names cannot be empty") if name.size == 0

          # Return value
          return Subsystem.create(:name => name)
        end

        expose :addSubsys do |args|
          args.declare :obj, :objId, :out, "The object ID of the newly-created Subsystem object."
          args.declare :name, :sstr, :in, "The name of the subsystem to create."
        end
        
        authorize_before :addSubsys, :WRITE
        
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
          args.declare :name, :sstr, :in, "The name of the parameter to remove."
        end

        authorize_before :removeParam, :WRITE

        # removeSubsys 
        # * name (sstr/I)
        def removeSubsys(name)
          # Print values of input parameters
          log.debug "removeSubsys: name => #{name.inspect}"
          Subsystem.find_first_by_name(name).delete
        end

        expose :removeSubsys do |args|
          args.declare :name, :sstr, :in, "The name of the subsystem to remove."
        end

        authorize_before :removeSubsys, :WRITE
        
        def storeinit(kwargs=nil)
          kwargs ||= {}
          options = kwargs.keys.map {|k| k.upcase}
          
          if options.include? "RESETDB"
            clear_db
          end
          
          if options.include? "REMOVE-SPURIOUS"
            remove_spurious_configs
          end
          
          Group.DEFAULT_GROUP
          
          # There's no harm in always creating this.
          Group.SKELETON_GROUP
          nil
        end
        
        authorize_before :storeinit, :ADMIN
        
        expose :storeinit do |args|
          args.declare :options, :map, :in, "Setting 'RESETDB' will reset the configuration database."
        end
        
        # <method name="makeSnapshot">
        #    <arg name="name" dir="I" type="sstr"
        #         desc="A name for this configuration.  A blank name will result
        #               in the store creating a name"/>
        # </method>
        
        def makeSnapshot(name)
          makeSnapshotWithOptions(name)
        end
        
        # XXX: this could be "none" or "read," since making a snapshot has no observable effect on configuration
        authorize_before :makeSnapshot, :WRITE
        
        expose :makeSnapshot do |args|
          args.declare :name, :sstr, :in, "A name for this configuration.  A blank name will result in the store creating a name"
        end

        def makeSnapshotWithOptions(name, opts=nil)
          opts = {"annotation"=>""}.merge(opts || {})
          name = Mrg::Grid::Config::Snapshot.autogen_name("Automatically generated snapshot") if name.size == 0
          fail(42, "Snapshot name #{name} already taken") if Snapshot.find_first_by_name(name)
          result = Snapshot.create(:name=>name, :annotation=>opts["annotation"])
          snaptext = ::Mrg::Grid::SerializedConfigs::ConfigSerializer.new(self, false).serialize.to_yaml
          result.snaptext = snaptext
        end
        
        # XXX: this could be "none" or "read," since making a snapshot has no observable effect on configuration
        authorize_before :makeSnapshotWithOptions, :WRITE

        expose :makeSnapshotWithOptions do |args|
          args.declare :name, :sstr, :in, "A name for this configuration.  A blank name will result in the store creating a name"
          args.declare :options, :map, :in, "Options for this snapshot.  Valid options include 'annotation', which must map to a string containing an annotation for this snapshot."
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

        authorize_before :loadSnapshot, :ADMIN
        
        expose :loadSnapshot do |args|
          args.declare :name, :sstr, :in, "A name for the snapshot to load."
        end
        
        def removeSnapshot(name)
          Snapshot.find_first_by_name(name).delete
        end
        
        # XXX: erring on the restrictive side here
        authorize_before :removeSnapshot, :ADMIN

        expose :removeSnapshot do |args|
          args.declare :name, :sstr, :in, "A name for the snapshot to remove."
        end

        def getMustChangeParams
          Parameter.s_that_must_change
        end
        
        authorize_before :getMustChangeParams, :READ

        expose :getMustChangeParams do |args|
          args.declare :params, :map, :out, "Parameters that must change; a map from names to (empty) default values"
        end
        
        [Feature, Group, Node, Parameter, Subsystem].each do |klass|
          define_method "check#{klass.name.split("::").pop}Validity".to_sym do |fset|
            log.debug "check#{klass.name.split("::").pop}Validity called:  set is #{fset}"
            entities = fset.sort.uniq
            klass.select_invalid(entities)
          end
          
          expose "check#{klass.name.split("::").pop}Validity".to_sym do |args|
            args.declare :set, :list, :in, "A set of #{klass.name} names to check for validity"
            args.declare "invalid#{klass.name.split("::").pop}s".to_sym, :list, :out, "A (possibly-empty) set consisting of all of the #{klass.name} names from the input set that do not correspond to valid #{klass.name}s"
          end
          
          authorize_before "check#{klass.name.split("::").pop}Validity".to_sym, :READ
        end
        
        [:Feature, :Group, :Node, :Parameter, :Subsystem].each do |klass|
          define_method "#{klass.to_s.downcase}s" do
            instances_of(klass)
          end
        end
        
        private
        
        def instances_of(klass)
          ::Mrg::Grid::Config.const_get(klass).find_all
        end
        
        def app
          Store.app rescue nil
        end
        
        def clear_db
          MAIN_DB_TABLES.each do |table|
            table.delete_all rescue table.find_all.each {|row| row.delete}
          end
        end

        def remove_spurious_configs
          old_count = VersionedNodeConfig.count
          VersionedNodeConfig.delete_spurious
          new_count = VersionedNodeConfig.count
          log.info(new_count == old_count ? "Inspected #{old_count} versioned configs" :  "Inspected #{old_count} versioned configs and removed #{old_count - new_count} spurious ones")
        end

        def validate_and_activate(validate_only=false, explicit_nodelist=nil, this_version=nil)
          
          unless ::Rhubarb::Persistence::db.transaction_active? || ConfigVersion.db.transaction_active?
            ConfigVersion.db.transaction do |ignored|
              return _validate_and_activate(validate_only, explicit_nodelist, this_version)
            end
          else
            return _validate_and_activate(validate_only, explicit_nodelist, this_version)
          end
          
        end

        def _validate_and_activate(validate_only=false, explicit_nodelist=nil, this_version=nil)
          dirty_nodes = explicit_nodelist || Node.get_dirty_nodes
          dirty_elements = DirtyElement.count
          this_version ||= ::Rhubarb::Util::timestamp
          nothing_changed = (dirty_nodes.size == 0)
          default_group_only = (nothing_changed && Node.count == 0)
          all_nodes = dirty_nodes.size == Node.count && !default_group_only
          warnings = []
          
          log.debug "entering validate_and_activate for an #{explicit_nodelist ? "explicit" : "implicit"} node list; we have #{dirty_elements} dirty element#{dirty_elements == 1 ? "" : "s"}; dirty node count is #{dirty_nodes.size} (#{all_nodes ? "all" : "not all"} nodes)"
          
          if default_group_only
            log.warn "Attempting to activate a configuration with no nodes; will simply check the configuration of the default group"
            dirty_nodes << Group.DEFAULT_GROUP
            warnings << "No nodes in configuration; only tested #{ENABLE_SKELETON_GROUP ? "default and skeleton groups" : "default group"}"
            nothing_changed = false
          elsif nothing_changed
            log.warn "User requested configuration #{validate_only ? "validation" : "activation"}, but no nodes have changed configurations since last activate."
            warnings << "No node configurations have changed since the last activated config; #{validate_only ? "validate" : "activate"} request will have no effect."
          end

          if ENABLE_SKELETON_GROUP && DirtyElement.find_first_by_grp(Group.SKELETON_GROUP)
            skeleton_node = TransientNode.new("+++SKELETON_NODE")
            skeleton_node.memberships = [Group.SKELETON_GROUP]
            dirty_nodes << skeleton_node
          end
          
          options = {}
          
          if ENV['WALLABY_USE_VALIDATE_CACHE'] && ENV['WALLABY_USE_VALIDATE_CACHE'].downcase == "never"
            options[:cache] = DummyCache.new
          else
            options[:cache] = ConfigDataCache.new(*dirty_nodes)
          end
          options[:save_for_version] = this_version unless validate_only
          
          bytes_left = MAX_ARG_SIZE - MAX_SIZE_CUSHION
          nodes_left = dirty_nodes.size
          
          node_pairs = dirty_nodes.inject([]) do |acc, node|
            if bytes_left <= 0
              acc << ["*", "More validation errors may have occured; stopped processing nodes with #{nodes_left} nodes left"]
              break acc
            end
            
            node_result = node.validate(options)
            nodes_left -= 1
            
            unless node_result == true
              acc << node_result
              bytes_left -= OBJECT_OVERHEAD
              bytes_left -= node_result[0].size
              node_result[1].each do |explain_k, explain_v|
                bytes_left -= explain_k.size
                bytes_left -= explain_v.inject(0) {|running_total,s| running_total += s.size}
              end
            end
            
            acc
          end
                    
          results = Hash[*node_pairs.flatten]
          
          warnings << results.delete("*") if results["*"]
          
          if validate_only || nothing_changed || results.keys.size > 0
            ConfigVersion[this_version].delete
            return [results, warnings]
          end
          
          # we're activating this configuration; save the default group configuration by itself 
          # if possible and if we aren't dealing with an explicit node list
          unless explicit_nodelist
            validate_and_activate(false, [Group.DEFAULT_GROUP], this_version) unless ConfigVersion.hasVersionedNodeConfig(Group::DEFAULT_GROUP_NAME, this_version)
          end
          
          log.debug "in validate_and_activate; just deleted dirty elements; count is #{DirtyElement.count}"
          DirtyElement.delete_all
          
          begin
            config_events_to(dirty_nodes, this_version, all_nodes) unless explicit_nodelist
          rescue Exception=>ex
            warnings << "Couldn't send configuration events:  #{ex.inspect}"
          end
          
          dirty_nodes.each {|dn| dn.last_updated_version = this_version if dn.respond_to? :last_updated_version }
          
          [results, warnings]
        end
        
        module PullEventGenerator
          include QmfV1Kludges

          def new_config_event(nodes, current_version)
            notice = NodeUpdatedNotice.new
            notice.nodes = nodes
            notice.version = current_version
            notice.bang!
          end

          def config_events_to(node_list, current_version, all_nodes=false)
            node_names = all_nodes ? ["*"] : node_list.map {|n| n.name}
            
            log.debug { "calling PullEventGenerator#config_events_to; node_names is #{node_names.inspect}, current_version is #{current_version.inspect}" }
            acc = {}
            bytes = 0
            
            node_names.sort.each do |node|
              if (bytes + node.size) > (MAX_ARG_SIZE - MAX_SIZE_CUSHION)
                new_config_event(acc, current_version)
                acc = {}
                bytes = 0
              end
              
              acc[node] = 1
              bytes += (node.size)
            end
            
            new_config_event(acc, current_version) if acc.size > 0
          end
        end

        include PullEventGenerator
      end
    end
  end
end
