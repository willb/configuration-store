require 'mrg/grid/config'
require 'set'
require 'yaml'

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
          def initialize(kwargs)
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
        field :included, Set
        field :conflicts, Set
        field :depends, Array
        field :subsystems, Set
      end
      
      class Group
        include DefaultStruct
        field :name, String
        field :is_identity_group, false
        field :params, Hash
      end
      
      class Parameter
        include DefaultStruct
        field :name, String
        field :kind, String
        field :default_val, String
        field :description, String
        field :must_change, false
        field :level, Fixnum
        field :needs_restart, false
      end
      
      class Node
        include DefaultStruct
        field :name, String
        field :pool, String
        field :idgroup, String
        field :membership, List
      end        
      
      class Subsystem
        include DefaultStruct
        field :name, String
        field :params, Set
      end
      
      class ConfigSerializer
        module QmfConfigSerializer
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
        end
        
        def serialize
          @struct.nodes = serialize_nodes
          @struct.groups = serialize_groups
          @struct.params = serialize_params
          @struct.features = serialize_features
          @struct.subsystems = serialize_subsystems
        end
        
        private
        def serialize_nodes
          get_instances(:Node).map do |n|
            node = get_object(n)
            out = Node.new
            out.name = node.GetName
            out.pool = node.GetPool
            # XXX:  idgroup should be set up automatically
            out.membership = FakeList.normalize(node.GetMemberships).to_a
            out
          end
        end
        
        def serialize_groups
          nil
        end
        
        def serialize_params
          nil
        end
        
        def serialize_features
          nil
        end
        
        def serialize_subsystems
          nil
        end
      end
    end
  end  
end
