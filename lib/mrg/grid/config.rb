# config.rb:  main wallaby libs include file
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
require 'spqr/app'

require 'rhubarb/rhubarb'

require 'mrg/grid/config/QmfUtils'
require 'mrg/grid/config/ArcUtils'
require 'mrg/grid/config/DataValidating'

require 'mrg/grid/config/ArcLabel'
require 'mrg/grid/config/Parameter'
require 'mrg/grid/config/Configuration'
require 'mrg/grid/config/Feature'
require 'mrg/grid/config/ConfigValidating'
require 'mrg/grid/config/Group'
require 'mrg/grid/config/Node'
require 'mrg/grid/config/NodeMembership'
require 'mrg/grid/config/Subsystem'
require 'mrg/grid/config/Snapshot'
require 'mrg/grid/config/DirtyElement'
require 'mrg/grid/config/Store'

module Mrg
  module Grid
    module Config
      autoload :MAIN_DB_TABLES, 'mrg/grid/config/dbmeta'
      autoload :SNAP_DB_TABLES, 'mrg/grid/config/dbmeta'
    end
  end
end
