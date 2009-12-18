require 'mrg/grid/config'
require 'set'
require 'yaml'

module Mrg
  module Grid
    module ConfigProxies
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
        field :membership, Set
      end
      
      class Parameter
        include DefaultStruct
        field :name, String
        field :kind, String
        field :default_val, String
        field :description, String
        field :must_change, false
        field :level, Fixnum
        field :needsRestart, false
      end
      
      class Node
        include DefaultStruct
        field :name, String
        field :pool, String
        field :idgroup, String
      end        
      
      class Subsystem
        include DefaultStruct
        field :name, String
        field :params, Set
      end
    end
  end  
end
