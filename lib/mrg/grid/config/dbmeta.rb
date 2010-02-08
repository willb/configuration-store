module Mrg
  module Grid
    module Config
      MAIN_DB_TABLES=[Mrg::Grid::Config::Node, Mrg::Grid::Config::Configuration, Mrg::Grid::Config::Feature, Mrg::Grid::Config::Group, Mrg::Grid::Config::Parameter, Mrg::Grid::Config::Subsystem, Mrg::Grid::Config::ArcLabel, Mrg::Grid::Config::ParameterArc, Mrg::Grid::Config::FeatureArc, Mrg::Grid::Config::FeatureParams, Mrg::Grid::Config::FeatureSubsys, Mrg::Grid::Config::NodeMembership, Mrg::Grid::Config::GroupParams, Mrg::Grid::Config::GroupFeatures, Mrg::Grid::Config::SubsystemParams]
      SNAP_DB_TABLES=[]
      DBVERSION = 1
      DBMIGRATIONS = []
      
    end
  end
end

require 'mrg/grid/config/dbmigrate/1'