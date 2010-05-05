# Configuration:  QMF configuration entity
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

require 'spqr/spqr'
require 'rhubarb/rhubarb'

module Mrg
  module Grid
    module Config
      class ConfigVersion
        include ::Rhubarb::Persisting
        include ::SPQR::Manageable

        qmf_package_name 'mrg.grid.config'
        qmf_class_name 'Configuration'
        ### Property method declarations
        # property uid uint32 

        declare_column :uid, :integer, :not_null, :primary_key
        declare_index_on :uid
        
        declare_column :version, :integer
        qmf_property :version, :uint64, :index=>true

        def [](node)
          getNodeConfig(node, false)
        end
        
        def []=(node, config)
          setNodeConfig(node, config, false)
        end

        def getNodeConfig(node, dofail=true)
          
        end
        
        def setNodeConfig(node, config, dofail=true)
          
        end
      end
      
      class VersionedNodeConfig
        include ::Rhubarb::Persisting
        
        declare_column :version, :integer, references(ConfigVersion)
        declare_column :node, :string
        declare_column :config, :object
      end
    end
  end
end
