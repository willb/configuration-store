# dbmeta.rb:  database support code and migrations
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

module Mrg
  module Grid
    module Config
      MAIN_DB_TABLES=[Mrg::Grid::Config::Feature, Mrg::Grid::Config::Group, Mrg::Grid::Config::Parameter, Mrg::Grid::Config::Subsystem, Mrg::Grid::Config::Node, Mrg::Grid::Config::ArcLabel, Mrg::Grid::Config::ParameterArc, Mrg::Grid::Config::FeatureArc, Mrg::Grid::Config::FeatureParams, Mrg::Grid::Config::FeatureSubsys, Mrg::Grid::Config::NodeMembership, Mrg::Grid::Config::GroupParams, Mrg::Grid::Config::GroupFeatures, Mrg::Grid::Config::SubsystemParams, Mrg::Grid::Config::DirtyElement]
      SNAP_DB_TABLES=[Mrg::Grid::Config::Snapshot, Mrg::Grid::Config::ConfigVersion, Mrg::Grid::Config::VersionedNode, Mrg::Grid::Config::VersionedParam, Mrg::Grid::Config::VersionedNodeConfig, Mrg::Grid::Config::VersionedNodeParamMapping]
      DBVERSION = 5
      DBMIGRATIONS = []
      
    end
  end
end

require 'mrg/grid/config/dbmigrate/1'
require 'mrg/grid/config/dbmigrate/2'
require 'mrg/grid/config/dbmigrate/3'
require 'mrg/grid/config/dbmigrate/4'