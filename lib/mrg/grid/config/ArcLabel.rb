require 'rhubarb/rhubarb'

module Mrg
  module Grid
    module Config

      # A label on a relationship between things (e.g. param/feature X
      # *conflicts with* param/feature Y)
      class ArcLabel
        include ::Rhubarb::Persisting
        declare_column :label, :string

        # Returns an ArcLabel that represents a conflict with a kind of
        # thing (e.g. ArcLabel.conflicts(:param) or ArcLabel.conflicts(:feature))
        def self.conflicts_with(kind)
          key = "conflicts_with_" + kind
          (ArcLabel.find_first_by_label(key) || ArcLabel.create(:label=>key))
        end
  
        # As conflicts_with, except it returns an edge describing a dependency
        def self.depends_on(kind)
          key = "depends_on_" + kind
          (ArcLabel.find_first_by_label(key) || ArcLabel.create(:label=>key))
        end

        # As conflicts_with, except it returns an edge describing inclusion
        def self.inclusion(kind)
          key = "includes_" + kind
          (ArcLabel.find_first_by_label(key) || ArcLabel.create(:label=>key))
        end

        # As conflicts_with, except it returns an edge describing implication
        def self.implication(kind)
          key = "implicates_" + kind
          (ArcLabel.find_first_by_label(key) || ArcLabel.create(:label=>key))
        end

      end
    end
  end
end