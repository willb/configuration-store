# ArcLabel.rb:  kinds of arcs
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

require 'rhubarb/rhubarb'

module Mrg
  module Grid
    module Config

      # A label on a relationship between things (e.g. param/feature X
      # *conflicts with* param/feature Y)
      class ArcLabel
        include ::Rhubarb::Persisting
        declare_column :label, :text

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
