#!/usr/bin/env ruby

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

DBLOC = (ARGV[0] or ":memory:")
puts "storing results to #{DBLOC}"
DO_CREATE = (DBLOC == ":memory:" or not File.exist?(DBLOC))

Rhubarb::Persistence::open(DBLOC)

if DO_CREATE
  classes = [Mrg::Grid::Config::Node, Mrg::Grid::Config::Configuration, Mrg::Grid::Config::Feature, Mrg::Grid::Config::Group, Mrg::Grid::Config::Parameter, Mrg::Grid::Config::Subsystem, Mrg::Grid::Config::ArcLabel, Mrg::Grid::Config::ParameterArc, Mrg::Grid::Config::FeatureParams, Mrg::Grid::Config::NodeMembership, Mrg::Grid::Config::GroupParams, Mrg::Grid::Config::GroupFeatures]
  classes.each do |cl| 
    puts "creating table for #{cl.name}..."
    cl.create_table
  end
end

app = SPQR::App.new(:loglevel => :debug, :user => "guest", :password => "guest")
app.register Mrg::Grid::Config::Store,Mrg::Grid::Config::Node,Mrg::Grid::Config::Configuration,Mrg::Grid::Config::Feature,Mrg::Grid::Config::Group,Mrg::Grid::Config::Parameter,Mrg::Grid::Config::Subsystem

app.main
