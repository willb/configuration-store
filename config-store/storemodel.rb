require 'sqlbackend'
require 'decoratedarray'

module GridConfigStore
  # A kind of param (integer, string, hostname, etc.)
  class Kind < Table
    declare_column :description, :string
  end
  
  # A configuration parameter
  class Param < Table
    declare_column :kind, :integer, :not_null
    declare_column :name, :string, references(Kind)
    declare_column :description, :string
    declare_column :not_null, :boolean
    declare_column :expert, :boolean
    declare_column :needs_restart, :boolean
  end
  
  # A label on a relationship between things (e.g. param X *conflicts with* param Y)
  class ArcLabel < Table
    declare_column :label, :string
  end
  
  # A relationship between parameters
  class ParamArc < Table
    declare_column :source, :integer, :not_null, references(Param, :on_delete=>:cascade)
    declare_column :dest, :integer, :not_null, references(Param, :on_delete=>:cascade)
    declare_column :label, :integer, :not_null, references(ArcLabel)
  end
  
  # A node in the pool
  class Node < Table
    declare_column :name, :string
    declare_column :pool, :string
    
    # Returns a list of groups of which this node is a member.  Appending a 
    # NodeGroup object to this list will create an association between this 
    # node and the given group.
    def groups
      onpush = Proc.new do |grp|
        GroupMembership.create :node=>row_id, :nodegroup=>grp.row_id
      end
      contents = GroupMembership.find_by_node(self.row_id).map {|gm| gm.group}
      DecoratedArray.new :push_callback=>onpush, :contents=>contents
    end
  end
  
  # An explicitly- or implicitly-declared group of nodes
  class NodeGroup < Table
    declare_column :name, :string
  end
  
  class GroupMembership < Table
    declare_column :node, :integer, :not_null, references(Node, :on_delete => :cascade)
    declare_column :nodegroup, :integer, :not_null, references(NodeGroup, :on_delete => :cascade)
    alias :group :nodegroup 
    alias :group= :nodegroup=
  end
  
  class Feature < Table
    declare_column :name, :string
  end
  
  # A relationship between features
  class FeatureArc < Table
    declare_column :source, :integer, :not_null, references(Feature, :on_delete=>:cascade)
    declare_column :dest, :integer, :not_null, references(Feature, :on_delete=>:cascade)
    declare_column :label, :integer, :not_null, references(ArcLabel)
  end
  
  # A relationship identifying which parameter/value pairs are implied by a given feature
  class FeatureParamMembership < Table
    declare_column :feature, :integer, :not_null, references(Feature, :on_delete=>:cascade)
    declare_column :param, :integer, :not_null, references(Param, :on_delete=>:cascade)
    declare_column :value, :string
    declare_column :version, :integer, :not_null # Need this?
    declare_column :enable, :boolean, :default, :true
  end
  
  class Configuration < Table
    declare_column :name, :string, :not_null
  end
  
  class ConfigurationGroupFeatureMapping < Table
    declare_column :configuration, :integer, :not_null, references(Configuration, :on_delete=>:cascade)
    declare_column :version, :integer, :not_null
    declare_column :group, :integer, :not_null, references(Group, :on_delete=>:cascade)
    declare_column :feature, :integer, :not_null, references(Feature, :on_delete=>:cascade)
    declare_column :enable, :boolean, :default, :true
  end

  class ConfigurationGroupParamMapping < Table
    declare_column :configuration, :integer, :not_null, references(Configuration, :on_delete=>:cascade)
    declare_column :version, :integer, :not_null
    declare_column :group, :integer, :not_null, references(Group, :on_delete=>:cascade)
    declare_column :param, :integer, :not_null, references(Param, :on_delete=>:cascade)
    declare_column :value, :string
    declare_column :enable, :boolean, :default, :true
  end
    
  class ConfigurationDefaultFeatureMapping < Table
    declare_column :configuration, :integer, :not_null, references(Configuration, :on_delete=>:cascade)
    declare_column :version, :integer, :not_null
    declare_column :feature, :integer, :not_null, references(Feature, :on_delete=>:cascade)
    declare_column :enable, :boolean, :default, :true
  end

  # TODO:  snapshots (tagged versions), query groups
end