# config-client.rb
# simple configuration store client library; presents the direct
# interface as a wrapper over the qmf interface
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

# FIXME:  most of this file could/should be dynamically generated, via, inter
# alia, a much smarter method_missing that introspected over qmf method
# results

require 'yaml'

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
        attr_reader :console
        
        def initialize(qmfo, console=nil)
          @qmfo = qmfo
          @console = console
        end
        
        def method_missing(m, *args)
          callargs = [m] + args
          @qmfo.send(*callargs)
        end
        
        def inspect
          "<#{self.class.name.to_s}: #{self.name rescue self.object_id}>"
        end

        def to_hash
          rhash = {}
          if self.class.respond_to? :client_hash_properties
            self.class.client_hash_properties.each do |prop|
              rhash[prop.to_s] = self.send(prop)
            end
          end

          if self.class.respond_to? :client_hash_methods
            self.class.client_hash_methods.each do |m|
              rhash[m.to_s] = self.send(m)
            end
          end
          
          if self.class.respond_to? :hash_postprocess
            rhash = self.class.hash_postprocess(rhash)
          end

          rhash
        end

        def to_yaml
          to_hash.to_yaml
        end
      end
      
      class Group < ClientObj
        def self.client_hash_properties
          @cyp ||= %w{is_identity_group name features params}
        end

        def self.client_hash_methods
          @cym ||= %w{membership getConfig}
        end
        
        def membership
          @qmfo.membership.nodes
        end
        
        def explain
          @qmfo.explain.explanation
        end
        
        def name
          @qmfo.name
        end
        
        def features
          @qmfo.features
        end
        
        def params
          @qmfo.params
        end
        
        def modifyFeatures(c,fs,o)
          @qmfo.modifyFeatures(c,fs,o)
        end
        
        def modifyParams(c,p,o={})
          @qmfo.modifyParams(c,p,o)
        end
        
        private
        include ObjResolver
      end

      class Parameter < ClientObj
        def self.client_hash_properties
          @cyp ||= %w{kind default description must_change visibility_level requires_restart depends conflicts}
        end

        def self.client_hash_methods
          @cym ||= %w{}
        end

        def name
          @qmfo.name
        end
        
        def kind
          @qmfo.kind
        end

        def setKind(t)
          @qmfo.setKind(t)
        end
        
        def default
          @qmfo.default
        end

        def setDefault(v)
          @qmfo.setDefault(v)
        end
        
        def description
          @qmfo.description
        end

        def setDescription(d)
          @qmfo.setDescription(d)
        end
        
        def visibility_level
          @qmfo.visibility_level
        end

        def setVisibilityLevel(level)
          @qmfo.setVisibilityLevel(level)
        end

        def requires_restart
          @qmfo.requires_restart
        end

        def setRequiresRestart(needsRestart)
          @qmfo.setRequiresRestart(needsRestart)
        end

        def must_change
          @qmfo.must_change
        end
        
        def setMustChange(mustChange)
          @qmfo.setMustChange(mustChange)
        end

        def depends
          @qmfo.depends
        end

        def modifyDepends(c,d,o)
          @qmfo.modifyDepends(c,d.uniq,o)
        end

        def conflicts
          @qmfo.conflicts
        end

        def modifyConflicts(c,co,o)
          @qmfo.modifyConflicts(c,co.uniq,o)
        end

        private
        include ObjResolver
      end
      
      class Feature < ClientObj
        def self.client_hash_properties
          @cyp ||= %w{name included_features params param_meta conflicts depends}
        end

        def self.client_hash_methods
          @cym ||= %w{}
        end

        def name
          @qmfo.name
        end
        
        def setName(name)
          @qmfo.setName(name)
        end
        
        def included_features()
          @qmfo.included_features
        end
        
        def modifyIncludedFeatures(command, features, options={})
          @qmfo.modifyIncludedFeatures(command, features, options)
        end
        
        def explain
          @qmfo.explain.explanation
        end
        
        def params()
          @qmfo.params
        end
        
        def param_meta()
          @qmfo.param_meta
        end
        
        def modifyParams(command,pvmap,options={})
          @qmfo.modifyParams(command,pvmap,options)
        end
        
        def modifyDepends(command, depends, options={})
          @qmfo.modifyDepends(command, depends, options)
        end
        
        def modifyConflicts(command, conflicts, options={})
          @qmfo.modifyConflicts(command, conflicts.uniq, options)
        end
        
        def modifySubsys(command, subsys, options={})
          @qmfo.modifySubsys(command, subsys.uniq, options)
        end
        
        def conflicts
          @qmfo.conflicts
        end

        def depends
          @qmfo.depends
        end
                
        private
        include ObjResolver
      end

      class Subsystem < ClientObj
        def self.client_hash_properties
          @cyp ||= %w{params}
        end

        def self.client_hash_methods
          @cym ||= %w{}
        end

        def name
          @qmfo.name
        end
        
        def params
          @qmfo.params
        end
        
        def modifyParams(command, params, options)
          @qmfo.modifyParams(command, params.uniq, options)
        end
        
        private
        include ObjResolver
      end

      class Node < ClientObj
        def self.client_hash_properties
          @cyp ||= %w{name provisioned last_checkin last_updated_version identity_group memberships}
        end

        def self.client_hash_methods
          @cym ||= %w{getConfig}
        end

        def self.hash_postprocess(h)
          h["identity_group"] = h["identity_group"].name
          h
        end

        def name
          @qmfo.name
        end
        
        def provisioned
          @qmfo.provisioned
        end

        def last_checkin
          @qmfo.last_checkin
        end

        def identity_group
          get_object(@qmfo.identity_group, Group)
        end

        def modifyMemberships(command, groups, options)
          @qmfo.modifyMemberships(command, groups, options)
        end

        def memberships
          @qmfo.memberships
        end

        def getConfig(options=nil)
          options ||= {}
          @qmfo.getConfig(options).config
        end
        
        def whatChanged(old_version, new_version)
          result = @qmfo.whatChanged(old_version, new_version)
          raise result.message if result.status != 0
          [result.params, result.restart, result.affected]
        end

        def explain
          @qmfo.explain.explanation
        end
        
        private
        include ObjResolver
      end

      class Store < ClientObj
        [:Feature, :Group, :Node, :Parameter, :Subsystem].each do |klass|
          mname = "check#{klass}Validity".to_sym
          define_method mname.to_sym do |fset|
            @qmfo.send(mname, fset).send("invalid#{klass}s")
          end
        end
        
        def getDefaultGroup
          get_object(@qmfo.getDefaultGroup().obj, Group)
        end
        
        def getGroup(query)
          get_object(@qmfo.getGroup(query).obj, Group)
        end
        
        def getGroupByName(name)
          getGroup("name"=>name)
        end
        
        def addExplicitGroup(name)
          get_object(@qmfo.addExplicitGroup(name).obj, Group)
        end

        def getExplicitGroup(name)
          get_object(@qmfo.getGroup({"NAME"=>name}).obj, Group)
        end

        def removeGroup(uid)
          @qmfo.removeGroup(uid)
          nil
        end

        def getFeature(name)
          get_object(@qmfo.getFeature(name).obj, Feature)
        end

        def addFeature(name)
          get_object(@qmfo.addFeature(name).obj, Feature)
        end

        def removeFeature(name)
          @qmfo.removeFeature(name)
          nil
        end

        def addNode(name, options=nil)
          options ||= {}
          get_object(@qmfo.addNodeWithOptions(name, options).obj, Node)
        end

        alias addNodeWithOptions addNode

        def getNode(name)
          get_object(@qmfo.getNode(name).obj, Node)
        end

        def removeNode(name)
          @qmfo.removeNode(name)
          nil
        end

        def addParam(name)
          get_object(@qmfo.addParam(name).obj, Parameter)
        end

        def getParam(name)
          get_object(@qmfo.getParam(name).obj, Parameter)
        end

        def removeParam(name)
          @qmfo.removeParam(name)
          nil
        end

        def addSubsys(name)
          get_object(@qmfo.addSubsys(name).obj, Subsystem)
        end

        def getSubsys(name)
          get_object(@qmfo.getSubsys(name).obj, Subsystem)
        end

        def removeSubsys(name)
          @qmfo.removeSubsys(name)
          nil
        end
        
        def activateConfig
          explain = @qmfo.activateConfiguration.explain
          explain.inject({}) do |acc, (node, node_explain)|
            acc[node] = node_explain.inject({}) do |ne_acc, (reason, ls)|
              ne_acc[reason] = ls
              ne_acc
            end
            acc
          end
        end

        def storeinit(kwargs=nil)
          kwargs ||= {}
          @qmfo.storeinit(kwargs)
        end

        [:Feature, :Group, :Node, :Parameter, :Subsystem].each do |klass|
          define_method "#{klass.to_s.downcase}s" do
            instances_of(klass)
          end
        end

        private
        include ObjResolver

        def instances_of(klass)
          console.objects(:class=>klass.to_s, :timeout=>45).map do |obj|
            ::Mrg::Grid::ConfigClient.const_get(klass.to_s).new(obj, console)
          end
        end
      end
    end
  end
end
