#!/usr/bin/env ruby

# creates non-existent tables in a preexisting db.  utility only.

require 'rubygems'

require 'spqr/spqr'
require 'spqr/app'

require 'mrg/grid/config/Store'
require 'mrg/grid/config/Node'
require 'mrg/grid/config/Configuration'
require 'mrg/grid/config/Feature'
require 'mrg/grid/config/Group'
require 'mrg/grid/config/Parameter'
require 'mrg/grid/config/Subsystem'

dbname = ":memory:"

op = OptionParser.new do |opts|
  opts.banner = "Usage create-tables.rb [options]"
  
  opts.on("-d", "--dbname FILE", "file for persistent storage (will be created if it doesn't exist)") do |db| 
    dbname = db
  end
  
end

begin
  op.parse!
rescue OptionParser::InvalidOption
  puts op
  exit
end

Rhubarb::Persistence::open(dbname)

classes = [Mrg::Grid::Config::Node, Mrg::Grid::Config::Configuration, Mrg::Grid::Config::Feature, Mrg::Grid::Config::Group, Mrg::Grid::Config::Parameter, Mrg::Grid::Config::Subsystem, Mrg::Grid::Config::ArcLabel, Mrg::Grid::Config::ParameterArc, Mrg::Grid::Config::FeatureArc, Mrg::Grid::Config::FeatureParams, Mrg::Grid::Config::FeatureSubsys, Mrg::Grid::Config::NodeMembership, Mrg::Grid::Config::GroupParams, Mrg::Grid::Config::GroupFeatures]
classes.each do |cl| 
  puts "creating table for #{cl.name} if necessary..."
  cl.create_table rescue nil
end

