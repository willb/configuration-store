
class ClientObject:
   def __init__(self, obj, console):
      self.console = console
      self.obj = obj
   
   def __getattr__(self, name):
      return self.obj.__getattr__(name)
   
   def get_object(self, obj_id, klass=None):
      obj = self.console.getObjects(_objectId=obj_id)[0]
      return klass and klass(obj, self.console) or obj
   
class ClientError(Exception):
   def __init__(self, code, text):
      self.code = code
      self.text = text
   
   def __str__(self):
      return(repr((self.code, self.text)))
   


class Snapshot(ClientObject):
   """com.redhat.grid.config:Snapshot"""

class Configuration(ClientObject):
   """com.redhat.grid.config:Configuration"""

class Group(ClientObject):
   """com.redhat.grid.config:Group"""
   # explanation (map/out) A structure representing where the parameters set on this group get their values.
   def explain(self):
      result = self.obj.explain()
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return result.outArgs['explanation']
   
   # command (sstr/in) Valid commands are 'ADD', 'REMOVE', and 'REPLACE'.
   # features (list/in) A list of features to apply to this group, in order of decreasing priority.
   # options (map/in) No options are supported at this time.
   def modifyFeatures(self, command, features, options={}):
      result = self.obj.modifyFeatures(command, features, options)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   # ret (int64/out) 0 if successful.
   def clearParams(self):
      result = self.obj.clearParams()
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return result.outArgs['ret']
   
   # feature (lstr/in)
   def addFeature(self, feature):
      result = self.obj.addFeature(feature)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   # command (sstr/in) Valid commands are 'ADD', 'REMOVE', and 'REPLACE'.
   # params (map/in) A map from parameter names to values as set as custom parameter mappings for this group (i.e. independently of any features that are enabled on this group)
   # options (map/in) No options are supported at this time.
   def modifyParams(self, command, params, options={}):
      result = self.obj.modifyParams(command, params, options)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   # name (sstr/in) A new name for this group; it must not be in use by another group.
   def setName(self, name):
      result = self.obj.setName(name)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   # feature (lstr/in)
   def removeFeature(self, feature):
      result = self.obj.removeFeature(feature)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   # nodes (list/out) A list of node names from the nodes that are members of this group.
   def membership(self):
      result = self.obj.membership()
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return result.outArgs['nodes']
   
   # config (map/out) Current parameter-value mappings for this group, including those from all enabled features and group-specific parameter mappings.
   def getConfig(self):
      result = self.obj.getConfig()
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return result.outArgs['config']
   
   # ret (int64/out) 0 if successful.
   def clearFeatures(self):
      result = self.obj.clearFeatures()
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return result.outArgs['ret']
   

class Parameter(ClientObject):
   """com.redhat.grid.config:Parameter"""
   # level (uint8/in) The new "visibility level" for this parameter.
   def setVisibilityLevel(self, level):
      result = self.obj.setVisibilityLevel(level)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   # needsRestart (bool/out) True if the application must be restarted to see a change to this parameter; false otherwise.
   def getRequiresRestart(self):
      result = self.obj.getRequiresRestart()
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return result.outArgs['needsRestart']
   
   # needsRestart (bool/in) True if the application must be restarted to see a change to this parameter; false otherwise.
   def setRequiresRestart(self, needsRestart):
      result = self.obj.setRequiresRestart(needsRestart)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   # description (lstr/in) A new description of this parameter.
   def setDescription(self, description):
      result = self.obj.setDescription(description)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   # command (sstr/in) Valid commands are 'ADD', 'REMOVE', and 'REPLACE'.
   # depends (list/in) A set of parameter names that this one depends on.
   # options (map/in) No options are supported at this time.
   def modifyDepends(self, command, depends, options={}):
      result = self.obj.modifyDepends(command, depends, options)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   # kind (sstr/in) The type of this parameter.
   def setKind(self, kind):
      result = self.obj.setKind(kind)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   # command (sstr/in) Valid commands are 'ADD', 'REMOVE', and 'REPLACE'.
   # conflicts (list/in) A set of parameter names that this parameter conflicts with.
   # options (map/in) No options are supported at this time.
   def modifyConflicts(self, command, conflicts, options={}):
      result = self.obj.modifyConflicts(command, conflicts, options)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   # mustChange (bool/in) True if the user must supply a value for this parameter; false otherwise.
   def setMustChange(self, mustChange):
      result = self.obj.setMustChange(mustChange)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   # default (lstr/in) The new default value for this parameter.
   def setDefault(self, default):
      result = self.obj.setDefault(default)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   

class Node(ClientObject):
   """com.redhat.grid.config:Node"""
   # version (uint32/in)
   def checkConfigVersion(self, version):
      result = self.obj.checkConfigVersion(version)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   # explanation (map/out) A structure representing where the parameters set on this node get their values.
   def explain(self):
      result = self.obj.explain()
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return result.outArgs['explanation']
   
   def makeProvisioned(self):
      result = self.obj.makeProvisioned()
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   def makeUnprovisioned(self):
      result = self.obj.makeUnprovisioned()
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   # command (sstr/in) Valid commands are 'ADD', 'REMOVE', and 'REPLACE'.
   # groups (list/in) A list of groups, in inverse priority order (most important first).
   # options (map/in) No options are supported at this time.
   def modifyMemberships(self, command, groups, options={}):
      result = self.obj.modifyMemberships(command, groups, options)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   # old_version (uint64/in) The old version.
   # new_version (uint64/in) The new version.
   # params (list/out) A list of parameters whose values changed between old_version and new_version.
   # restart (list/out) A list of subsystems that must be restarted as a result of the changes between old_version and new_version.
   # affected (list/out) A list of subsystems that must re-read their configurations as a result of the changes between old_version and new_version.
   def whatChanged(self, old_version, new_version):
      result = self.obj.whatChanged(old_version, new_version)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return result.outArgs['params'], result.outArgs['restart'], result.outArgs['affected']
   
   # options (map/in) Valid options include 'version', which maps to a version number.  If this is supplied, return the latest version not newer than 'version'.
   # config (map/out) A map from parameter names to values representing the configuration for this node.
   def getConfig(self, options={}):
      result = self.obj.getConfig(options)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return result.outArgs['config']
   
   def checkin(self):
      result = self.obj.checkin()
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   

class Store(ClientObject):
   """com.redhat.grid.config:Store"""
   # set (list/in) A set of Mrg::Grid::Config::Feature names to check for validity
   # invalidFeatures (list/out) A (possibly-empty) set consisting of all of the Mrg::Grid::Config::Feature names from the input set that do not correspond to valid Mrg::Grid::Config::Features
   def checkFeatureValidity(self, set):
      result = self.obj.checkFeatureValidity(set)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return result.outArgs['invalidFeatures']
   
   # name (sstr/in) A name for the snapshot to load.
   def loadSnapshot(self, name):
      result = self.obj.loadSnapshot(name)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   # obj (ref/out) The object ID of the requested Parameter object.
   # name (sstr/in) The name of the parameter to find.
   def getParam(self, name):
      result = self.obj.getParam(name)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return self.get_object(result.outArgs['obj'], Parameter)
   
   # name (sstr/in) The name of the group to remove.
   def removeGroup(self, name):
      result = self.obj.removeGroup(name)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   # set (list/in) A set of Mrg::Grid::Config::Parameter names to check for validity
   # invalidParameters (list/out) A (possibly-empty) set consisting of all of the Mrg::Grid::Config::Parameter names from the input set that do not correspond to valid Mrg::Grid::Config::Parameters
   def checkParameterValidity(self, set):
      result = self.obj.checkParameterValidity(set)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return result.outArgs['invalidParameters']
   
   # obj (ref/out) The object ID of the newly-created Node object.
   # name (sstr/in) The name of the node to create.
   def addNode(self, name):
      result = self.obj.addNode(name)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return self.get_object(result.outArgs['obj'], Node)
   
   # obj (ref/out) The object ID of the newly-created Parameter object.
   # name (sstr/in) The name of the parameter to create.
   def addParam(self, name):
      result = self.obj.addParam(name)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return self.get_object(result.outArgs['obj'], Parameter)
   
   # obj (ref/out) The object ID of the newly-created Feature object.
   # name (sstr/in) The name of the feature to create.
   def addFeature(self, name):
      result = self.obj.addFeature(name)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return self.get_object(result.outArgs['obj'], Feature)
   
   # obj (ref/out) The object ID of the Feature object corresponding to the requested feature.
   # name (sstr/in) The name of the feature to search for.
   def getFeature(self, name):
      result = self.obj.getFeature(name)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return self.get_object(result.outArgs['obj'], Feature)
   
   # name (sstr/in) A name for this configuration.  A blank name will result in the store creating a name
   def makeSnapshot(self, name):
      result = self.obj.makeSnapshot(name)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   # set (list/in) A set of Mrg::Grid::Config::Group names to check for validity
   # invalidGroups (list/out) A (possibly-empty) set consisting of all of the Mrg::Grid::Config::Group names from the input set that do not correspond to valid Mrg::Grid::Config::Groups
   def checkGroupValidity(self, set):
      result = self.obj.checkGroupValidity(set)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return result.outArgs['invalidGroups']
   
   # obj (ref/out) The object ID of the requested Subsystem object.
   # name (sstr/in) The name of the subsystem to find.
   def getSubsys(self, name):
      result = self.obj.getSubsys(name)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return self.get_object(result.outArgs['obj'], Subsystem)
   
   # explain (map/out) A map containing an explanation of why the configuration isn't valid, or an empty map if the configuration was successfully activated.
   # warnings (list/out) A set of warnings encountered during configuration activation.
   def activateConfiguration(self):
      result = self.obj.activateConfiguration()
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return result.outArgs['explain'], result.outArgs['warnings']
   
   # name (sstr/in) The name of the feature to remove.
   def removeFeature(self, name):
      result = self.obj.removeFeature(name)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   # set (list/in) A set of Mrg::Grid::Config::Subsystem names to check for validity
   # invalidSubsystems (list/out) A (possibly-empty) set consisting of all of the Mrg::Grid::Config::Subsystem names from the input set that do not correspond to valid Mrg::Grid::Config::Subsystems
   def checkSubsystemValidity(self, set):
      result = self.obj.checkSubsystemValidity(set)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return result.outArgs['invalidSubsystems']
   
   # options (map/in) Setting 'RESETDB' will reset the configuration database.
   def storeinit(self, options={}):
      result = self.obj.storeinit(options)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   # obj (ref/out) The object ID of the retrieved Node object.
   # name (sstr/in) The name of the node to find.  If no node exists with this name, the store will create an unprovisioned node with the given name.
   def getNode(self, name):
      result = self.obj.getNode(name)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return self.get_object(result.outArgs['obj'], Node)
   
   # obj (ref/out) The object ID of the newly-created Subsystem object.
   # name (sstr/in) The name of the subsystem to create.
   def addSubsys(self, name):
      result = self.obj.addSubsys(name)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return self.get_object(result.outArgs['obj'], Subsystem)
   
   # name (sstr/in) The name of the group to search for.
   # obj (ref/out) The object ID of the Group object corresponding to the requested group.
   def getGroupByName(self, name):
      result = self.obj.getGroupByName(name)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return self.get_object(result.outArgs['obj'], Group)
   
   # set (list/in) A set of Mrg::Grid::Config::Node names to check for validity
   # invalidNodes (list/out) A (possibly-empty) set consisting of all of the Mrg::Grid::Config::Node names from the input set that do not correspond to valid Mrg::Grid::Config::Nodes
   def checkNodeValidity(self, set):
      result = self.obj.checkNodeValidity(set)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return result.outArgs['invalidNodes']
   
   # name (sstr/in) A name for the snapshot to remove.
   def removeSnapshot(self, name):
      result = self.obj.removeSnapshot(name)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   # name (sstr/in) The name of the parameter to remove.
   def removeParam(self, name):
      result = self.obj.removeParam(name)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   # obj (ref/out) The object ID of the Group object corresponding to the default group.
   def getDefaultGroup(self):
      result = self.obj.getDefaultGroup()
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return self.get_object(result.outArgs['obj'], Group)
   
   # name (sstr/in) The name of the node to remove.
   def removeNode(self, name):
      result = self.obj.removeNode(name)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   # obj (ref/out) The object ID of the Group object corresponding to the newly-created group.
   # name (sstr/in) The name of the newly-created group.  Names beginning with '+++' are reserved for internal use.
   def addExplicitGroup(self, name):
      result = self.obj.addExplicitGroup(name)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return self.get_object(result.outArgs['obj'], Group)
   
   # params (map/out) Parameters that must change; a map from names to (empty) default values
   def getMustChangeParams(self):
      result = self.obj.getMustChangeParams()
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return result.outArgs['params']
   
   # name (sstr/in) The name of the subsystem to remove.
   def removeSubsys(self, name):
      result = self.obj.removeSubsys(name)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   # explain (map/out) A map containing an explanation of why the configuration isn't valid, or an empty map if the configuration was successfully activated.
   # warnings (list/out) A set of warnings encountered during configuration activation.
   def validateConfiguration(self):
      result = self.obj.validateConfiguration()
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return result.outArgs['explain'], result.outArgs['warnings']
   
   # obj (ref/out) The object ID of the Group object corresponding to the requested group.
   # query (map/in) A map from a query type to a query parameter. The queryType can be either 'ID' or 'Name'. 'ID' queryTypes will search for a group with the ID supplied as a parameter. 'Name' queryTypes will search for a group with the name supplied as a parameter.
   def getGroup(self, query):
      result = self.obj.getGroup(query)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return self.get_object(result.outArgs['obj'], Group)
   

class Subsystem(ClientObject):
   """com.redhat.grid.config:Subsystem"""
   # command (sstr/in) Valid commands are 'ADD', 'REMOVE', and 'REPLACE'.
   # params (list/in) A list representing the set of parameter names that this subsystem should be interested in (for ADD and REPLACE) or should not be interested in (for REMOVE).
   # options (map/in) No options are supported at this time.
   def modifyParams(self, command, params, options={}):
      result = self.obj.modifyParams(command, params, options)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   

class Feature(ClientObject):
   """com.redhat.grid.config:Feature"""
   # explanation (map/out) A structure representing where the parameters set on this feature get their values.
   def explain(self):
      result = self.obj.explain()
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return result.outArgs['explanation']
   
   # ret (int64/out) 0 if successful.
   def clearParams(self):
      result = self.obj.clearParams()
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return result.outArgs['ret']
   
   # command (sstr/in) Valid commands are 'ADD', 'REMOVE', and 'REPLACE'.
   # params (map/in) A map from parameter names to their corresponding values, as strings, for this feature.  To use the default value for a parameter, give it the value 0 (as an int).
   # options (map/in) No options are supported at this time.
   def modifyParams(self, command, params, options={}):
      result = self.obj.modifyParams(command, params, options)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   # name (sstr/in) A new name for this feature; this name must not already be in use by another feature.
   def setName(self, name):
      result = self.obj.setName(name)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   # command (sstr/in) Valid commands are 'ADD', 'REMOVE', and 'REPLACE'.
   # features (list/in) A list, in inverse priority order, of the names of features that this feature should include (in the case of ADD or REPLACE), or should not include (in the case of REMOVE).
   # options (map/in) No options are supported at this time.
   def modifyIncludedFeatures(self, command, features, options={}):
      result = self.obj.modifyIncludedFeatures(command, features, options)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   # command (sstr/in) Valid commands are 'ADD', 'REMOVE', and 'REPLACE'.
   # depends (list/in) A list of other features a feature depends on, in priority order.  ADD adds deps to the end of this feature's deps, in the order supplied, REMOVE removes features from the dependency list, and REPLACE replaces the dependency list with the supplied list.
   # options (map/in) No options are supported at this time.
   def modifyDepends(self, command, depends, options={}):
      result = self.obj.modifyDepends(command, depends, options)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   # command (sstr/in) Valid commands are 'ADD', 'REMOVE', and 'REPLACE'.
   # conflicts (list/in) A set of other feature names that conflict with the feature
   # options (map/in) No options are supported at this time.
   def modifyConflicts(self, command, conflicts, options={}):
      result = self.obj.modifyConflicts(command, conflicts, options)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
