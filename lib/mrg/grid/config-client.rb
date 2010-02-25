# config-client.rb
# simple configuration store client library; presents the direct
# interface as a wrapper over the qmf interface

# FIXME:  most of this file could/should be dynamically generated, via, inter
# alia, a much smarter method_missing that introspected over qmf method
# results and converted input sets and lists to FakeSet/FakeList

require 'mrg/grid/config'

module Mrg
  module Grid
    module ConfigClient

      module ObjResolver
        def get_object(obj_id, klass=nil)
          obj = @console.object(:object_id=>obj_id)
          klass ? klass.new(obj, @console) : obj
        end
      end

      class ClientObj
        def initialize(qmfo, console=nil)
          @qmfo = qmfo
          @console = console
        end
        
        def method_missing(m, *args)
          callargs = [m] + args
          @qmfo.send(*callargs)
        end
      end

      class Group < ClientObj
        def GetMembership
          FakeList.normalize(@qmfo.GetMembership.nodes).to_a
        end
        
        def GetName
          @qmfo.GetName.name
        end
        
        def GetFeatures
          FakeList.normalize(@qmfo.GetFeatures.features).to_a
        end
        
        def ModifyFeatures(c,fs,o)
          @qmfo.ModifyFeatures(c,FakeList[*fs],o)
        end
        
        def GetParams
          @qmfo.GetParams.params
        end
        
        def ModifyParams(c,p,o={})
          @qmfo.ModifyParams(c,p,o)
        end
        
        private
        include ObjResolver
      end

      class Parameter < ClientObj
        def name
          @qmfo.name
        end
        
        def GetType
          @qmfo.GetType.args["type"]
        end

        def SetType(t)
          @qmfo.SetType(t)
        end
        
        def GetDefault
          @qmfo.GetDefault.default
        end

        def SetDefault(v)
          @qmfo.SetDefault(v)
        end
        
        def GetDescription
          @qmfo.GetDescription.description
        end

        def SetDescription(d)
          @qmfo.SetDescription(d)
        end
        
        def GetVisibilityLevel
          @qmfo.GetVisibilityLevel.level
        end

        def SetVisibilityLevel(level)
          @qmfo.SetVisibilityLevel(level)
        end

        def GetRequiresRestart
          @qmfo.GetRequiresRestart.needsRestart
        end

        def SetRequiresRestart(needsRestart)
          @qmfo.SetRequiresRestart(needsRestart)
        end

        def GetDefaultMustChange
          @qmfo.GetDefaultMustChange.mustChange
        end
        
        def SetDefaultMustChange(mustChange)
          @qmfo.SetDefaultMustChange(mustChange)
        end

        def GetDepends
          @qmfo.GetDepends.depends
        end

        def ModifyDepends(c,d,o)
          @qmfo.ModifyDepends(c,FakeSet[*d],o)
        end

        def GetConflicts
          @qmfo.GetConflicts.conflicts
        end

        def ModifyConflicts(c,co,o)
          @qmfo.ModifyConflicts(c,FakeSet[*co],o)
        end

        private
        include ObjResolver
      end

      class Feature < ClientObj
        def GetName
          @qmfo.GetName.name
        end
        
        def SetName(name)
          @qmfo.SetName(name)
        end
        
        def GetFeatures()
          FakeList.normalize(@qmfo.GetFeatures.features).to_a
        end
        
        def ModifyFeatures(command, features, options={})
          @qmfo.ModifyFeatures(command, FakeList[*features], options)
        end
        
        def GetParams()
          @qmfo.GetParams.params
        end
        
        def ModifyParams(command,pvmap,options={})
          @qmfo.ModifyParams(command,pvmap,options)
        end
        
        def ModifyDepends(command, depends, options={})
          @qmfo.ModifyDepends(command, FakeList[*depends], options)
        end
        
        def ModifyConflicts(command, conflicts, options={})
          @qmfo.ModifyConflicts(command, FakeSet[*conflicts], options)
        end
        
        def ModifySubsys(command, subsys, options={})
          @qmfo.ModifySubsys(command, FakeSet[*subsys], options)
        end
        
        def GetConflicts
          @qmfo.GetConflicts.conflicts.keys
        end

        def GetSubsys
          @qmfo.GetSubsys.subsystems.keys
        end

        def GetDepends
          FakeList.normalize(@qmfo.GetDepends.depends).to_a
        end
        
        private
        include ObjResolver
      end

      class Subsystem < ClientObj
        def name
          @qmfo.name
        end
        
        def GetParams
          @qmfo.GetParams.params.keys
        end
        
        def ModifyParams(command, params, options)
          @qmfo.ModifyParams(command, FakeSet[*params], options)
        end
        
        private
        include ObjResolver
      end

      class Node < ClientObj
        def name
          @qmfo.name
        end
        
        def provisioned
          @qmfo.provisioned
        end

        def last_checkin
          @qmfo.last_checkin
        end

        def GetIdentityGroup
          get_object(@qmfo.GetIdentityGroup.group, Group)
        end

        def ModifyMemberships(command, groups, options)
          @qmfo.ModifyMemberships(command, FakeList[*groups], options)
        end

        def GetMemberships
          FakeList.normalize(@qmfo.GetMemberships.groups).to_a
        end

        def GetConfig
          @qmfo.GetConfig.config
        end

        private
        include ObjResolver
      end

      class Store < ClientObj
        def GetGroup(query)
          get_object(@qmfo.GetGroup(query).obj, Group)
        end

        def AddExplicitGroup(name)
          get_object(@qmfo.AddExplicitGroup(name).obj, Group)
        end

        def RemoveGroup(uid)
          @qmfo.RemoveGroup(uid)
          nil
        end

        def GetFeature(name)
          get_object(@qmfo.GetFeature(name).obj, Feature)
        end

        def AddFeature(name)
          get_object(@qmfo.AddFeature(name).obj, Feature)
        end

        def RemoveFeature(name)
          @qmfo.RemoveFeature(name)
          nil
        end

        def AddNode(name)
          get_object(@qmfo.AddNode(name).obj, Node)
        end

        def GetNode(name)
          get_object(@qmfo.GetNode(name).obj, Node)
        end

        def RemoveNode(name)
          @qmfo.RemoveNode(name)
          nil
        end

        def AddParam(name)
          get_object(@qmfo.AddParam(name).obj, Parameter)
        end

        def GetParam(name)
          get_object(@qmfo.GetParam(name).obj, Parameter)
        end

        def RemoveParam(name)
          @qmfo.RemoveParam(name)
          nil
        end

        def AddSubsys(name)
          get_object(@qmfo.AddSubsys(name).obj, Subsystem)
        end

        def GetSubsys(name)
          get_object(@qmfo.GetSubsys(name).obj, Subsystem)
        end

        def RemoveSubsys(name)
          @qmfo.RemoveSubsys(name)
          nil
        end
        
        def ActivateConfig
          explain = @qmfo.ActivateConfiguration.explain
          explain.inject({}) do |acc, (node, node_explain)|
            acc[node] = node_explain.inject({}) do |ne_acc, (reason, ls)|
              ne_acc[reason] = ls.keys
              ne_acc
            end
            acc
          end
        end

        private
        include ObjResolver

      end

    end
  end
end
