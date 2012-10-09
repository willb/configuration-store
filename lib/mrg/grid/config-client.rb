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
    class WallabyClientError < RuntimeError
      attr_reader :status
      def initialize(status, m)
        @status = status
        super(m)
      end
    end
    
    module ConfigClient

      module AnnotatableObject
        def setAnnotation(na)
          check_result(@qmfo.setAnnotation(na))
        end
      end

      module ObjResolver
        def get_object(obj_id, klass=nil)
          obj = @console.object(:object_id=>obj_id)
          klass ? klass.new(obj, @console) : obj
        end
        
        def check_result(value)
          raise WallabyClientError.new(value.status, value.text) unless value.status == 0
          value
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
        include AnnotatableObject
        
        def self.client_hash_properties
          @cyp ||= %w{is_identity_group name features params annotation}
        end

        def self.client_hash_methods
          @cym ||= %w{membership getConfig}
        end
        
        def membership
          check_result(@qmfo.membership).nodes
        end
        
        def explain
          check_result(@qmfo.explain).explanation
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

        def getConfig
          @qmfo.getConfig.config
        end
        
        def modifyFeatures(c,fs,o)
          check_result(@qmfo.modifyFeatures(c,fs,o))
        end
        
        def modifyParams(c,p,o={})
          check_result(@qmfo.modifyParams(c,p,o))
        end
        
        def setName(name)
          check_result(@qmfo.setName(name))
        end

        private
        include ObjResolver
      end

      class Parameter < ClientObj
        include AnnotatableObject
        
        def self.client_hash_properties
          @cyp ||= %w{kind default description must_change visibility_level requires_restart depends conflicts annotation}
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
          check_result(@qmfo.setKind(t))
        end
        
        def default
          @qmfo.default
        end

        def setDefault(v)
          check_result(@qmfo.setDefault(v))
        end
        
        def description
          @qmfo.description
        end

        def setDescription(d)
          check_result(@qmfo.setDescription(d))
        end
        
        def visibility_level
          @qmfo.visibility_level
        end

        def setVisibilityLevel(level)
          check_result(@qmfo.setVisibilityLevel(level))
        end

        def requires_restart
          @qmfo.requires_restart
        end

        def setRequiresRestart(needsRestart)
          check_result(@qmfo.setRequiresRestart(needsRestart))
        end

        def must_change
          @qmfo.must_change
        end
        
        def setMustChange(mustChange)
          check_result(@qmfo.setMustChange(mustChange))
        end

        def depends
          @qmfo.depends
        end

        def modifyDepends(c,d,o)
          check_result(@qmfo.modifyDepends(c,d.uniq,o))
        end

        def conflicts
          @qmfo.conflicts
        end

        def modifyConflicts(c,co,o)
          check_result(@qmfo.modifyConflicts(c,co.uniq,o))
        end

        private
        include ObjResolver
      end
      
      class Feature < ClientObj
        include AnnotatableObject
        
        def self.client_hash_properties
          @cyp ||= %w{name included_features params param_meta conflicts depends annotation}
        end

        def self.client_hash_methods
          @cym ||= %w{}
        end

        def name
          @qmfo.name
        end

        def setName(name)
          check_result(@qmfo.setName(name))
        end        
        
        def included_features()
          @qmfo.included_features
        end
        
        def modifyIncludedFeatures(command, features, options={})
          check_result(@qmfo.modifyIncludedFeatures(command, features, options))
        end
        
        def explain
          check_result(@qmfo.explain).explanation
        end
        
        def params()
          @qmfo.params
        end
        
        def param_meta()
          @qmfo.param_meta
        end
        
        def modifyParams(command,pvmap,options={})
          check_result(@qmfo.modifyParams(command,pvmap,options))
        end
        
        def modifyDepends(command, depends, options={})
          check_result(@qmfo.modifyDepends(command, depends, options))
        end
        
        def modifyConflicts(command, conflicts, options={})
          check_result(@qmfo.modifyConflicts(command, conflicts.uniq, options))
        end
        
        def modifySubsys(command, subsys, options={})
          check_result(@qmfo.modifySubsys(command, subsys.uniq, options))
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
        include AnnotatableObject
        
        def self.client_hash_properties
          @cyp ||= %w{params annotation}
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
          check_result(@qmfo.modifyParams(command, params.uniq, options))
        end
        
        private
        include ObjResolver
      end

      class Node < ClientObj
        include AnnotatableObject  
        
        def self.client_hash_properties
          @cyp ||= %w{name provisioned last_checkin last_updated_version identity_group memberships annotation}
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
          get_object(@qmfo.identity_group, Group) rescue nil
        end

        def modifyMemberships(command, groups, options)
          check_result(@qmfo.modifyMemberships(command, groups, options))
        end

        def memberships
          @qmfo.memberships
        end

        def getConfig(options=nil)
          options ||= {}
          check_result(@qmfo.getConfig(options)).config
        end
        
        def whatChanged(old_version, new_version)
          result = check_result(@qmfo.whatChanged(old_version, new_version))
          [result.params, result.restart, result.affected]
        end

        def explain
          check_result(@qmfo.explain).explanation
        end
        
        private
        include ObjResolver
      end

      class Store < ClientObj
        [:Feature, :Group, :Node, :Parameter, :Subsystem].each do |klass|
          mname = "check#{klass}Validity".to_sym
          define_method mname.to_sym do |fset|
            check_result(@qmfo.send(mname, fset)).send("invalid#{klass}s")
          end
        end
        
        [:getDefaultGroup, :getSkeletonGroup].each do |msg|
          define_method msg do
            get_object(check_result(@qmfo.send(msg)).obj, Group)
          end
        end

        def set_user_privs(user, role, options=nil)
          options||={}
          check_result(@qmfo.set_user_privs(user, role, options))
          0
        end

        def del_user(user, options=nil)
          options||={}
          check_result(@qmfo.del_user(user, options))
          0
        end

        def users(options=nil)
          options||={}
          check_result(@qmfo.users(options)).roles
        end

        def getGroup(query)
          get_object(check_result(@qmfo.getGroup(query)).obj, Group)
        end
        
        def getGroupByName(name)
          getGroup("name"=>name)
        end
        
        def addExplicitGroup(name)
          get_object(check_result(@qmfo.addExplicitGroup(name)).obj, Group)
        end

        def getExplicitGroup(name)
          get_object(check_result(@qmfo.getGroup({"NAME"=>name})).obj, Group)
        end

        def removeGroup(uid)
          check_result(@qmfo.removeGroup(uid))
          nil
        end

        def getFeature(name)
          get_object(check_result(@qmfo.getFeature(name)).obj, Feature)
        end

        def addFeature(name)
          get_object(check_result(@qmfo.addFeature(name)).obj, Feature)
        end

        def removeFeature(name)
          check_result(@qmfo.removeFeature(name))
          nil
        end

        def addNode(name, options=nil)
          options ||= {}
          get_object(check_result(@qmfo.addNodeWithOptions(name, options)).obj, Node)
        end

        alias addNodeWithOptions addNode

        def getNode(name)
          get_object(check_result(@qmfo.getNode(name)).obj, Node)
        end

        def removeNode(name)
          check_result(@qmfo.removeNode(name))
          nil
        end

        def affectedEntities(options=nil)
          options ||= {}
          check_result(@qmfo.affectedEntities(options)).result
        end

        def affectedNodes(options=nil)
          options ||= {}
          check_result(@qmfo.affectedNodes(options)).result
        end

        def addParam(name)
          get_object(check_result(@qmfo.addParam(name)).obj, Parameter)
        end

        def getParam(name)
          get_object(check_result(@qmfo.getParam(name)).obj, Parameter)
        end

        def getMustChangeParams
          check_result(@qmfo.getMustChangeParams).params
        end

        def removeParam(name)
          check_result(@qmfo.removeParam(name))
          nil
        end

        def addSubsys(name)
          get_object(check_result(@qmfo.addSubsys(name)).obj, Subsystem)
        end

        def getSubsys(name)
          get_object(check_result(@qmfo.getSubsys(name)).obj, Subsystem)
        end

        def removeSubsys(name)
          check_result(@qmfo.removeSubsys(name))
          nil
        end
        
        def activateConfig
          explain = check_result(@qmfo.activateConfiguration).explain
          explain.inject({}) do |acc, (node, node_explain)|
            acc[node] = node_explain.inject({}) do |ne_acc, (reason, ls)|
              ne_acc[reason] = ls
              ne_acc
            end
            acc
          end
        end
        
        alias activateConfiguration activateConfig

        def makeSnapshotWithOptions(name, options=nil)
          options ||= {}
          check_result(@qmfo.makeSnapshotWithOptions(name, options))
          0
        end
        
        alias makeSnapshot makeSnapshotWithOptions
        
        def loadSnapshot(name)
          check_result(@qmfo.loadSnapshot(name))
          0
        end

        def removeSnapshot(name)
          check_result(@qmfo.removeSnapshot(name))
          0
        end

        def storeinit(kwargs=nil)
          kwargs ||= {}
          check_result(@qmfo.storeinit(kwargs))
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
