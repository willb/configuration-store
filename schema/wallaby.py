
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
   def explain(self):
      """
      Returns a structure representing where the parameters set on this group get their values.
      """
      result = self.obj.explain()
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return result.outArgs['explanation']
   
   def modifyFeatures(self, command, features, options={}):
      """
      Parameters:
      * Valid commands are 'ADD', 'REMOVE', and 'REPLACE'.
      * A list of features to apply to this group, in order of decreasing priority.
      * No options are supported at this time.
      """
      result = self.obj.modifyFeatures(command, features, options)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   def clearParams(self):
      """
      Returns 0 if successful.
      """
      result = self.obj.clearParams()
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return result.outArgs['ret']
   
   def addFeature(self, feature):
      """
      Parameters:
      * (feature:lstr)
      """
      result = self.obj.addFeature(feature)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   def modifyParams(self, command, params, options={}):
      """
      Parameters:
      * Valid commands are 'ADD', 'REMOVE', and 'REPLACE'.
      * A map from parameter names to values as set as custom parameter mappings for this group (i.e. independently of any features that are enabled on this group)
      * No options are supported at this time.
      """
      result = self.obj.modifyParams(command, params, options)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   def setName(self, name):
      """
      Parameters:
      * A new name for this group; it must not be in use by another group.
      """
      result = self.obj.setName(name)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   def removeFeature(self, feature):
      """
      Parameters:
      * (feature:lstr)
      """
      result = self.obj.removeFeature(feature)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   def membership(self):
      """
      Returns a list of node names from the nodes that are members of this group.
      """
      result = self.obj.membership()
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return result.outArgs['nodes']
   
   def getConfig(self):
      """
      Returns current parameter-value mappings for this group, including those from all enabled features and group-specific parameter mappings.
      """
      result = self.obj.getConfig()
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return result.outArgs['config']
   
   def clearFeatures(self):
      """
      Returns 0 if successful.
      """
      result = self.obj.clearFeatures()
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return result.outArgs['ret']
   

class Parameter(ClientObject):
   """com.redhat.grid.config:Parameter"""
   def setVisibilityLevel(self, level):
      """
      Parameters:
      * The new "visibility level" for this parameter.
      """
      result = self.obj.setVisibilityLevel(level)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   def getRequiresRestart(self):
      """
      Returns true if the application must be restarted to see a change to this parameter; false otherwise.
      """
      result = self.obj.getRequiresRestart()
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return result.outArgs['needsRestart']
   
   def setRequiresRestart(self, needsRestart):
      """
      Parameters:
      * True if the application must be restarted to see a change to this parameter; false otherwise.
      """
      result = self.obj.setRequiresRestart(needsRestart)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   def setDescription(self, description):
      """
      Parameters:
      * A new description of this parameter.
      """
      result = self.obj.setDescription(description)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   def modifyDepends(self, command, depends, options={}):
      """
      Parameters:
      * Valid commands are 'ADD', 'REMOVE', and 'REPLACE'.
      * A set of parameter names that this one depends on.
      * No options are supported at this time.
      """
      result = self.obj.modifyDepends(command, depends, options)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   def setKind(self, kind):
      """
      Parameters:
      * The type of this parameter.
      """
      result = self.obj.setKind(kind)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   def modifyConflicts(self, command, conflicts, options={}):
      """
      Parameters:
      * Valid commands are 'ADD', 'REMOVE', and 'REPLACE'.
      * A set of parameter names that this parameter conflicts with.
      * No options are supported at this time.
      """
      result = self.obj.modifyConflicts(command, conflicts, options)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   def setMustChange(self, mustChange):
      """
      Parameters:
      * True if the user must supply a value for this parameter; false otherwise.
      """
      result = self.obj.setMustChange(mustChange)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   def setDefault(self, default):
      """
      Parameters:
      * The new default value for this parameter.
      """
      result = self.obj.setDefault(default)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   

class Node(ClientObject):
   """com.redhat.grid.config:Node"""
   def checkConfigVersion(self, version):
      """
      Parameters:
      * (version:uint32)
      """
      result = self.obj.checkConfigVersion(version)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   def explain(self):
      """
      Returns a structure representing where the parameters set on this node get their values.
      """
      result = self.obj.explain()
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return result.outArgs['explanation']
   
   def makeProvisioned(self):
      """
      """
      result = self.obj.makeProvisioned()
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   def makeUnprovisioned(self):
      """
      """
      result = self.obj.makeUnprovisioned()
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   def modifyMemberships(self, command, groups, options={}):
      """
      Parameters:
      * Valid commands are 'ADD', 'REMOVE', and 'REPLACE'.
      * A list of groups, in inverse priority order (most important first).
      * No options are supported at this time.
      """
      result = self.obj.modifyMemberships(command, groups, options)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   def whatChanged(self, old_version, new_version):
      """
      Parameters:
      * The old version.
      * The new version.
      Returns a tuple consisting of:
      * A list of parameters whose values changed between old_version and new_version.
      * A list of subsystems that must be restarted as a result of the changes between old_version and new_version.
      * A list of subsystems that must re-read their configurations as a result of the changes between old_version and new_version.
      """
      result = self.obj.whatChanged(old_version, new_version)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return result.outArgs['params'], result.outArgs['restart'], result.outArgs['affected']
   
   def getConfig(self, options={}):
      """
      Parameters:
      * Valid options include 'version', which maps to a version number.  If this is supplied, return the latest version not newer than 'version'.
      Returns a map from parameter names to values representing the configuration for this node.
      """
      result = self.obj.getConfig(options)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return result.outArgs['config']
   
   def checkin(self):
      """
      """
      result = self.obj.checkin()
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   

class Store(ClientObject):
   """com.redhat.grid.config:Store"""
   def checkFeatureValidity(self, set):
      """
      Parameters:
      * A set of Mrg::Grid::Config::Feature names to check for validity
      Returns a (possibly-empty) set consisting of all of the Mrg::Grid::Config::Feature names from the input set that do not correspond to valid Mrg::Grid::Config::Features
      """
      result = self.obj.checkFeatureValidity(set)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return result.outArgs['invalidFeatures']
   
   def loadSnapshot(self, name):
      """
      Parameters:
      * A name for the snapshot to load.
      """
      result = self.obj.loadSnapshot(name)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   def getParam(self, name):
      """
      Parameters:
      * The name of the parameter to find.
      Returns the object ID of the requested Parameter object.
      """
      result = self.obj.getParam(name)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return self.get_object(result.outArgs['obj'], Parameter)
   
   def removeGroup(self, name):
      """
      Parameters:
      * The name of the group to remove.
      """
      result = self.obj.removeGroup(name)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   def checkParameterValidity(self, set):
      """
      Parameters:
      * A set of Mrg::Grid::Config::Parameter names to check for validity
      Returns a (possibly-empty) set consisting of all of the Mrg::Grid::Config::Parameter names from the input set that do not correspond to valid Mrg::Grid::Config::Parameters
      """
      result = self.obj.checkParameterValidity(set)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return result.outArgs['invalidParameters']
   
   def addNode(self, name):
      """
      Parameters:
      * The name of the node to create.
      Returns the object ID of the newly-created Node object.
      """
      result = self.obj.addNode(name)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return self.get_object(result.outArgs['obj'], Node)
   
   def addParam(self, name):
      """
      Parameters:
      * The name of the parameter to create.
      Returns the object ID of the newly-created Parameter object.
      """
      result = self.obj.addParam(name)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return self.get_object(result.outArgs['obj'], Parameter)
   
   def addFeature(self, name):
      """
      Parameters:
      * The name of the feature to create.
      Returns the object ID of the newly-created Feature object.
      """
      result = self.obj.addFeature(name)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return self.get_object(result.outArgs['obj'], Feature)
   
   def getFeature(self, name):
      """
      Parameters:
      * The name of the feature to search for.
      Returns the object ID of the Feature object corresponding to the requested feature.
      """
      result = self.obj.getFeature(name)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return self.get_object(result.outArgs['obj'], Feature)
   
   def makeSnapshot(self, name):
      """
      Parameters:
      * A name for this configuration.  A blank name will result in the store creating a name
      """
      result = self.obj.makeSnapshot(name)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   def checkGroupValidity(self, set):
      """
      Parameters:
      * A set of Mrg::Grid::Config::Group names to check for validity
      Returns a (possibly-empty) set consisting of all of the Mrg::Grid::Config::Group names from the input set that do not correspond to valid Mrg::Grid::Config::Groups
      """
      result = self.obj.checkGroupValidity(set)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return result.outArgs['invalidGroups']
   
   def getSubsys(self, name):
      """
      Parameters:
      * The name of the subsystem to find.
      Returns the object ID of the requested Subsystem object.
      """
      result = self.obj.getSubsys(name)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return self.get_object(result.outArgs['obj'], Subsystem)
   
   def activateConfiguration(self):
      """
      Returns a tuple consisting of:
      * A map containing an explanation of why the configuration isn't valid, or an empty map if the configuration was successfully activated.
      * A set of warnings encountered during configuration activation.
      """
      result = self.obj.activateConfiguration()
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return result.outArgs['explain'], result.outArgs['warnings']
   
   def removeFeature(self, name):
      """
      Parameters:
      * The name of the feature to remove.
      """
      result = self.obj.removeFeature(name)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   def checkSubsystemValidity(self, set):
      """
      Parameters:
      * A set of Mrg::Grid::Config::Subsystem names to check for validity
      Returns a (possibly-empty) set consisting of all of the Mrg::Grid::Config::Subsystem names from the input set that do not correspond to valid Mrg::Grid::Config::Subsystems
      """
      result = self.obj.checkSubsystemValidity(set)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return result.outArgs['invalidSubsystems']
   
   def storeinit(self, options={}):
      """
      Parameters:
      * Setting 'RESETDB' will reset the configuration database.
      """
      result = self.obj.storeinit(options)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   def getNode(self, name):
      """
      Parameters:
      * The name of the node to find.  If no node exists with this name, the store will create an unprovisioned node with the given name.
      Returns the object ID of the retrieved Node object.
      """
      result = self.obj.getNode(name)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return self.get_object(result.outArgs['obj'], Node)
   
   def addSubsys(self, name):
      """
      Parameters:
      * The name of the subsystem to create.
      Returns the object ID of the newly-created Subsystem object.
      """
      result = self.obj.addSubsys(name)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return self.get_object(result.outArgs['obj'], Subsystem)
   
   def getGroupByName(self, name):
      """
      Parameters:
      * The name of the group to search for.
      Returns the object ID of the Group object corresponding to the requested group.
      """
      result = self.obj.getGroupByName(name)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return self.get_object(result.outArgs['obj'], Group)
   
   def checkNodeValidity(self, set):
      """
      Parameters:
      * A set of Mrg::Grid::Config::Node names to check for validity
      Returns a (possibly-empty) set consisting of all of the Mrg::Grid::Config::Node names from the input set that do not correspond to valid Mrg::Grid::Config::Nodes
      """
      result = self.obj.checkNodeValidity(set)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return result.outArgs['invalidNodes']
   
   def removeSnapshot(self, name):
      """
      Parameters:
      * A name for the snapshot to remove.
      """
      result = self.obj.removeSnapshot(name)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   def removeParam(self, name):
      """
      Parameters:
      * The name of the parameter to remove.
      """
      result = self.obj.removeParam(name)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   def getDefaultGroup(self):
      """
      Returns the object ID of the Group object corresponding to the default group.
      """
      result = self.obj.getDefaultGroup()
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return self.get_object(result.outArgs['obj'], Group)
   
   def removeNode(self, name):
      """
      Parameters:
      * The name of the node to remove.
      """
      result = self.obj.removeNode(name)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   def addExplicitGroup(self, name):
      """
      Parameters:
      * The name of the newly-created group.  Names beginning with '+++' are reserved for internal use.
      Returns the object ID of the Group object corresponding to the newly-created group.
      """
      result = self.obj.addExplicitGroup(name)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return self.get_object(result.outArgs['obj'], Group)
   
   def getMustChangeParams(self):
      """
      Returns parameters that must change; a map from names to (empty) default values
      """
      result = self.obj.getMustChangeParams()
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return result.outArgs['params']
   
   def removeSubsys(self, name):
      """
      Parameters:
      * The name of the subsystem to remove.
      """
      result = self.obj.removeSubsys(name)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   def validateConfiguration(self):
      """
      Returns a tuple consisting of:
      * A map containing an explanation of why the configuration isn't valid, or an empty map if the configuration was successfully activated.
      * A set of warnings encountered during configuration activation.
      """
      result = self.obj.validateConfiguration()
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return result.outArgs['explain'], result.outArgs['warnings']
   
   def getGroup(self, query):
      """
      Parameters:
      * A map from a query type to a query parameter. The queryType can be either 'ID' or 'Name'. 'ID' queryTypes will search for a group with the ID supplied as a parameter. 'Name' queryTypes will search for a group with the name supplied as a parameter.
      Returns the object ID of the Group object corresponding to the requested group.
      """
      result = self.obj.getGroup(query)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return self.get_object(result.outArgs['obj'], Group)
   

class Subsystem(ClientObject):
   """com.redhat.grid.config:Subsystem"""
   def modifyParams(self, command, params, options={}):
      """
      Parameters:
      * Valid commands are 'ADD', 'REMOVE', and 'REPLACE'.
      * A list representing the set of parameter names that this subsystem should be interested in (for ADD and REPLACE) or should not be interested in (for REMOVE).
      * No options are supported at this time.
      """
      result = self.obj.modifyParams(command, params, options)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   

class Feature(ClientObject):
   """com.redhat.grid.config:Feature"""
   def explain(self):
      """
      Returns a structure representing where the parameters set on this feature get their values.
      """
      result = self.obj.explain()
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return result.outArgs['explanation']
   
   def clearParams(self):
      """
      Returns 0 if successful.
      """
      result = self.obj.clearParams()
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return result.outArgs['ret']
   
   def modifyParams(self, command, params, options={}):
      """
      Parameters:
      * Valid commands are 'ADD', 'REMOVE', and 'REPLACE'.
      * A map from parameter names to their corresponding values, as strings, for this feature.  To use the default value for a parameter, give it the value 0 (as an int).
      * No options are supported at this time.
      """
      result = self.obj.modifyParams(command, params, options)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   def setName(self, name):
      """
      Parameters:
      * A new name for this feature; this name must not already be in use by another feature.
      """
      result = self.obj.setName(name)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   def modifyIncludedFeatures(self, command, features, options={}):
      """
      Parameters:
      * Valid commands are 'ADD', 'REMOVE', and 'REPLACE'.
      * A list, in inverse priority order, of the names of features that this feature should include (in the case of ADD or REPLACE), or should not include (in the case of REMOVE).
      * No options are supported at this time.
      """
      result = self.obj.modifyIncludedFeatures(command, features, options)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   def modifyDepends(self, command, depends, options={}):
      """
      Parameters:
      * Valid commands are 'ADD', 'REMOVE', and 'REPLACE'.
      * A list of other features a feature depends on, in priority order.  ADD adds deps to the end of this feature's deps, in the order supplied, REMOVE removes features from the dependency list, and REPLACE replaces the dependency list with the supplied list.
      * No options are supported at this time.
      """
      result = self.obj.modifyDepends(command, depends, options)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
   def modifyConflicts(self, command, conflicts, options={}):
      """
      Parameters:
      * Valid commands are 'ADD', 'REMOVE', and 'REPLACE'.
      * A set of other feature names that conflict with the feature
      * No options are supported at this time.
      """
      result = self.obj.modifyConflicts(command, conflicts, options)
      if result.status != 0:
         raise ClientError(result.status, result.text)
      return
   
