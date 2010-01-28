require 'mrg/grid/config/QmfUtils'
require 'set'
require 'yaml'

FakeList = Mrg::Grid::Config::FakeList
FakeSet = Mrg::Grid::Config::FakeSet

module Mrg
  module Grid
    module SerializedConfigs
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
      
      class Feature
        include DefaultStruct
        field :name, String
        field :params, Hash
        field :included, Array
        field :conflicts, Set
        field :depends, Array
        field :subsystems, Set
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
        field :pool, String
        field :idgroup, String
        field :membership, Array
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
            s
          end
        end
        
        module QmfHelpers
          def listify(ls)
            FakeList[*ls]
          end
          
          def setify(ls)
            FakeSet[*ls]
          end
        end
        
        def initialize(store, ymltxt)
          @store = store
          
          if @store.class.to_s == "Mrg::Grid::Config::Store"
            # "internal" -- not operating over qmf
            class << self
              include InternalHelpers
            end
          else
            # operating over QMF via the config-client lib
            class << self
              include QmfHelpers
            end
          end
          
          yrepr = YAML::parse(ymltxt).transform
          
          @nodes = dictify(yrepr.nodes)
          @groups = dictify(yrepr.groups)
          @params = dictify(yrepr.params)
          @features = dictify(yrepr.features)
          @subsystems = dictify(yrepr.subsystems)
          
          @callbacks = []
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
            node = @store.AddNode(name)
            node.SetPool(old_node.GetPool)
            memberships = old_node.membership
            if memberships.size > 0
              @callbacks << lambda do
                node.ModifyMemberships("ADD", listify(memberships), {})
              end
            end
          end
        end
        
        def create_groups
          @groups.each do |name, old_group|
            group = nil
            if name.index("+++") == 0
              # this is an identity or default group; don't create it
              group = @store.GetGroup(name)
            else
              group = @store.AddGroup(name)
            end
            
            if old_group.features.size > 0
              @callbacks << lambda do
                group.ModifyFeatures("ADD", listify(old_group.features), {})
              end
            end
            
            if old_group.params.size > 0
              @callbacks << lambda do
                group.ModifyParams("ADD", old_group.params, {})
              end
            end
          end
        end
        
        def create_params
          @params.each do |name, old_param|
            puts "#{name} --> #{name.inspect}"
            puts "#{old_param} --> #{old_param.inspect}"
            
            param = @store.AddParam(name)
            param.SetType(old_param.kind)
            param.SetDefault(old_param.default_val)
            param.SetDescription(old_param.description)
            param.SetDefaultMustChange(old_param.must_change)
            param.SetVisibilityLevel(old_param.level)
            param.SetRequiresRestart(old_param.needs_restart)

            {:conflicts=>:ModifyConflicts,:depends=>:ModifyDepends}.each do |get,set|
              if old_param.send(get).size > 0
                @callbacks << lambda do
                  param.send(set, "ADD", setify(old_param.send(get)), {})
                end
              end
            end
          end
        end
        
        def create_features
          @features.each do |name, old_feature|
            feature = @store.AddFeature(name)
            [[:params, :ModifyParams, :skk],[:included, :ModifyFeatures, :listify],[:conflicts, :ModifyConflicts, :setify],[:depends, :ModifyDepends, :listify],[:subsystems, :ModifySubsys, :setify]].each do |get,set,xform|
              if old_feature.send(get).size > 0
                @callbacks << lambda do
                  feature.send(set, "ADD", self.send(xform, old_feature.send(get)), {})
                end
              end              
            end
          end
        end
        
        def create_subsystems
          @subsystems.each do |name, old_ss|
            subsys = @store.AddSubsys(name)
            if old_ss.params.size > 0
              @callbacks << lambda do
                subsys.ModifyParams("ADD", setify(old_ss.params), {})
              end
            end
          end
        end
        
        def create_relationships
          @callbacks.each {|cb| cb.call}
          @callbacks = []
        end
        
        def dictify(ls)
          Hash[*ls.map {|obj| [(obj.name rescue obj.GetName), obj]}.flatten]
        end
        
        def skk(x)
          x
        end
      end
      
      class ConfigSerializer
        module QmfConfigSerializer
          # this is a no-op if we're using ConfigClients
          def get_object(o)
            o
          end
          
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
          @struct.nodes = serialize_nodes
          @struct.groups = serialize_groups
          @struct.params = serialize_params
          @struct.features = serialize_features
          @struct.subsystems = serialize_subsystems
          @struct
        end
        
        private
        def serialize_nodes
          get_instances(:Node).map do |n|
            node = get_object(n)
            out = Node.new
            out.name = node.name
            out.pool = node.GetPool
            out.membership = FakeList.normalize(node.GetMemberships).to_a
            out
          end
        end
        
        def serialize_groups
          get_instances(:Group).map do |g|
            group = get_object(g)
            out = Group.new
            out.name = group.GetName
            out.is_identity_group = group.is_identity_group
            out.features = FakeList.normalize(group.GetFeatures).to_a
            out.params = group.GetParams
            out
          end
        end
        
        def serialize_params
          get_instances(:Parameter).map do |p|
            param = get_object(p)
            out = Parameter.new
            out.name = param.name
            out.kind = param.GetType
            out.default_val = param.GetDefault.to_s
            out.description = param.GetDescription
            out.must_change = param.GetDefaultMustChange
            out.level = param.GetVisibilityLevel
            out.needs_restart = param.GetRequiresRestart
            out.conflicts = fs_normalize(param.GetConflicts)
            out.depends = fs_normalize(param.GetDepends)
            out
          end
        end
        
        def serialize_features
          get_instances(:Feature).map do |f|
            feature = get_object(f)
            out = Feature.new
            out.name = feature.GetName
            out.params = feature.GetParams
            out.included = FakeList.normalize(feature.GetFeatures).to_a
            out.conflicts = fs_normalize(feature.GetConflicts)
            out.depends = FakeList.normalize(feature.GetDepends).to_a
            out.subsystems = fs_normalize(feature.GetSubsys)
            out
          end
        end
        
        def serialize_subsystems
          get_instances(:Subsystem).map do |s|
            subsys = get_object(s)
            out = Subsystem.new
            out.name = subsys.name
            out.params = fs_normalize(subsys.GetParams)
            out
          end
        end
        
        def fs_normalize(fs)
          return fs if fs.is_a? Array
          fs.keys
        end
      end
    end
  end  
end
