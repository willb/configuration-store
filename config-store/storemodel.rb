require 'sqlbackend'
require 'decoratedarray'


module GridConfigStore
  # TODO: query-backed groups, store sesame info
  # XXX: should feature definitions be versioned?

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
  
  # A label on a relationship between things (e.g. param/feature X
  # *conflicts with* param/feature Y)
  class ArcLabel < Table
    declare_column :label, :string

    # Returns an ArcLabel that represents a conflict with a kind of
    # thing (e.g. ArcLabel.conflicts(:param) or ArcLabel.conflicts(:feature))
    
    def self.conflicts_with(kind)
      key = ("conflicts_with_" + kind).to_sym
      @kinds ||= {}
      @kinds[key] ||= ArcLabel.find_by_label(key.to_s) or ArcLabel.new(:label=>key.to_s)
    end
    
    # As conflicts_with, except it returns an edge describing a dependency
    def self.depends_on(kind)
      key = ("depends_on_" + kind).to_sym
      @kinds ||= {}
      @kinds[key] ||= ArcLabel.find_by_label(key.to_s) or ArcLabel.new(:label=>key.to_s)
    end

    
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
      contents = GroupMembership.find_by_node(self.row_id).map {|gm| gm.group }
      DecoratedArray.new :push_callback=>onpush, :contents=>contents
    end
  end
  
  # An explicitly- (TODO: or implicitly-) declared group of nodes
  class NodeGroup < Table
    declare_column :name, :string
  end
  
  class GroupMembership < Table
    declare_column :node, :integer, :not_null, references(Node, :on_delete => :cascade)
    declare_column :nodegroup, :integer, :not_null, references(NodeGroup, :on_delete => :cascade)

    alias :created :version
    alias :group :nodegroup 
    alias :group= :nodegroup=
  end
  
  class Feature < Table
    declare_column :name, :string

    # Returns true if this feature conflicts with the supplied feature
    def conflicts?(f)
      @@feature_conflict ||= ArcLabel.conflicts_with :feature
      a_from = FeatureArc.arcs :source=>self, :dest=>f, :label=>@@feature_conflict
      a_to = FeatureArc.arcs :dest=>self, :source=>f, :label=>@@feature_conflict
      (a_from + a_to).size > 0
    end


    # Returns true if this feature depends on the supplied feature
    def dependence?(f)
      @@feature_depend ||= ArcLabel.depends_on :feature
      res = FeatureArc.arcs :source=>self, :dest=>f, :label=>@@feature_depend
      res.size > 0
    end

    # Returns true if this feature is depended on by the supplied feature
    def dependent?(f)
      @@feature_depend ||= ArcLabel.depends_on :feature
      res = FeatureArc.arcs :dest=>self, :source=>f, :label=>@@feature_depend
      res.size > 0
    end

    # Returns a list of features that conflict with this one.
    # Appending a Feature object to this list will create a "conflict"
    # association between this feature and that feature. 
    def conflicts
      @@feature_conflict ||= ArcLabel.conflicts_with :feature
      onpush = Proc.new do |f|
        if not self.conflicts? f
          FeatureArc.create :source=>self, :dest=>self, :label=>@@feature_conflict
        end
      end
      contents_src = FeatureArc.arcs_implicating :feature=>row_id, :label=>@@feature_conflict.row_id
      DecoratedArray.new :push_callback=>onpush, :contents=>contents
    end

    # Returns a list of features that depend on this one.
    # Appending a Feature object to this list will create a "dependency"
    # association between this feature and that feature. 
    def dependents
      @@feature_depend ||= ArcLabel.depends_on :feature
      onpush = Proc.new do |f|
        if not self.dependent? f
          FeatureArc.create :source=>self, :dest=>f, :label=>@@feature_depend
        end
      end
      contents_src = FeatureArc.arcs_from :source=>self, :label=>@@feature_depend
      DecoratedArray.new :push_callback=>onpush, :contents=>contents
    end

    # Returns a list of features that this one depends on.
    # Appending a Feature object to this list will create a "dependency"
    # association between that feature and this feature. 
    def dependences
      @@feature_depend ||= ArcLabel.depends_on :feature
      onpush = Proc.new do |f|
        if not self.dependence? f
          FeatureArc.create :source=>f, :dest=>self, :label=>@@feature_depend
        end
      end
      contents_src = FeatureArc.arcs_to :source=>self, :label=>@@feature_depend
      DecoratedArray.new :push_callback=>onpush, :contents=>contents
    end

  end
  
  # A relationship between features
  class FeatureArc < Table
    alias :created :version

    declare_column :source, :integer, :not_null, references(Feature, :on_delete=>:cascade)
    declare_column :dest, :integer, :not_null, references(Feature, :on_delete=>:cascade)
    declare_column :label, :integer, :not_null, references(ArcLabel)
    declare_column :deleted, :boolean, :default, :false

    declare_query :arcs, "source = :source and dest = :dest and label = :label"
    declare_query :arcs_from, "source = :source and label = :label"
    declare_query :arcs_to, "dest = :dest and label = :label"
    
    # XXX:  need to select by version, only get max, also get deleted status
    declare_custom_query :arcs_implicating, "select min(row_id), source, dest, label from __TABLE__ group by source, dest, label where (source = :feature or dest = :feature) and label = :label"
  end
  
  # A relationship identifying which parameter/value pairs are implied by a given feature
  class FeatureParamMembership < Table
    alias :created :version

    declare_column :feature, :integer, :not_null, references(Feature, :on_delete=>:cascade)
    declare_column :param, :integer, :not_null, references(Param, :on_delete=>:cascade)
    declare_column :value, :string
    declare_column :enable, :boolean, :default, :true
  end
  
  class Configuration < Table
    declare_column :name, :string, :not_null
  end
  
  class ConfigurationGroupFeatureMapping < Table
    alias :created :version

    declare_column :configuration, :integer, :not_null, references(Configuration, :on_delete=>:cascade)
    declare_column :group, :integer, :not_null, references(Group, :on_delete=>:cascade)
    declare_column :feature, :integer, :not_null, references(Feature, :on_delete=>:cascade)
    declare_column :enable, :boolean, :default, :true
  end

  class ConfigurationGroupParamMapping < Table
    alias :created :version

    declare_column :configuration, :integer, :not_null, references(Configuration, :on_delete=>:cascade)
    declare_column :group, :integer, :not_null, references(Group, :on_delete=>:cascade)
    declare_column :param, :integer, :not_null, references(Param, :on_delete=>:cascade)
    declare_column :value, :string
    declare_column :enable, :boolean, :default, :true
  end
    
  class ConfigurationDefaultFeatureMapping < Table
    alias :created :version

    declare_column :configuration, :integer, :not_null, references(Configuration, :on_delete=>:cascade)
    declare_column :feature, :integer, :not_null, references(Feature, :on_delete=>:cascade)
    declare_column :enable, :boolean, :default, :true
  end

  # Versioning is transparent; we use created-on timestamps from the model
  class ConfigurationSnapshot < Table
    alias :created :version

    declare_column :name, :string, :not_null
  end

end
