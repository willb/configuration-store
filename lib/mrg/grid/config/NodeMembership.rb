require 'spqr/spqr'
require 'rhubarb/rhubarb'

require 'mrg/grid/config/Node'
require 'mrg/grid/config/Group'

module Mrg
  module Grid
    module Config
      class NodeMembership
        include ::Rhubarb::Persisting
        declare_column :node, :integer, references(Node, :on_delete=>:cascade)
        declare_column :grp, :integer, references(Group, :on_delete=>:cascade)
      end
    end
  end
end
