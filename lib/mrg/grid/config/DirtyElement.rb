require 'mrg/grid/config'

module Mrg
  module Grid
    module Config
      class DirtyElement
        include ::Rhubarb::Persisting
        KIND_EVERYTHING = 1 << 0
        KIND_NODE = 1 << 16
        KIND_GROUP = 1 << 2
        KIND_PARAMETER = 1 << 3
        KIND_FEATURE = 1 << 1
        KIND_SUBSYSTEM = 1 << 4
        
        declare_column :kind, :integer, :not_null
        declare_column :node, :integer, references(Node, :on_delete=>:cascade)
        declare_column :grp, :integer, references(Group, :on_delete=>:cascade)
        declare_column :parameter, :integer, references(Parameter, :on_delete=>:cascade)
        declare_column :feature, :integer, references(Feature, :on_delete=>:cascade)
        declare_column :subsystem, :integer, references(Subsystem, :on_delete=>:cascade)
        
        declare_custom_query :get_dirty_list, "SELECT * FROM __TABLE__ ORDER BY kind ASC"
        
        def self.dirty_node(node)
          self.create(:kind=>KIND_NODE, :node=>node) unless self.find_first_by_node(node)
        end
        
        def self.dirty_group(group)
          self.create(:kind=>KIND_GROUP, :grp=>group) unless self.find_first_by_grp(group)
        end
        
        def self.dirty_parameter(param)
          self.create(:kind=>KIND_PARAMETER, :parameter=>param) unless self.find_first_by_parameter(parameter)
        end
        
        def self.dirty_feature(feature)
          self.create(:kind=>KIND_FEATURE, :feature=>feature) unless self.find_first_by_feature(feature)
        end
        
        def self.dirty_subsystem(subsystem)
          self.create(:kind=>KIND_SUBSYSTEM, :subsystem=>subsystem) unless self.find_first_by_subsystem(subsystem)
        end
      end
    end
  end
end
