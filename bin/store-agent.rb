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

dbname = ":memory:"
host = "localhost"
port = 5672
username = nil
password = nil
debug = :warn

op = OptionParser.new do |opts|
  opts.banner = "Usage store-agent.rb [options]"
  
  opts.on("-d", "--dbname FILE", "file for persistent storage (will be created if it doesn't exist)") do |db| 
    dbname = db
  end
  
  opts.on("-h", "--host HOSTNAME", "qpid broker host (default localhost)") do |h|
    host = h
  end

  opts.on("-p", "--port NUM", "qpid broker port (default 5672)") do |num|
    port = num.to_i
  end
  
  opts.on("-U", "--user NAME", "qpid username") do |name|
    username = name
  end
  
  opts.on("-P", "--password PASS", "qpid password") do |pass|
    password = pass
  end
  
  opts.on("-v", "--verbose", "output verbose debugging info") do
    debug = :debug
  end
end

begin
  op.parse!
rescue OptionParser::InvalidOption
  puts op
  exit
end

puts "storing results to #{dbname}"
DO_CREATE = (dbname == ":memory:" or not File.exist?(dbname))

Rhubarb::Persistence::open(dbname)

if DO_CREATE
  classes = [Mrg::Grid::Config::Node, Mrg::Grid::Config::Configuration, Mrg::Grid::Config::Feature, Mrg::Grid::Config::Group, Mrg::Grid::Config::Parameter, Mrg::Grid::Config::Subsystem, Mrg::Grid::Config::ArcLabel, Mrg::Grid::Config::ParameterArc, Mrg::Grid::Config::FeatureParams, Mrg::Grid::Config::NodeMembership, Mrg::Grid::Config::GroupParams, Mrg::Grid::Config::GroupFeatures]
  classes.each do |cl| 
    puts "creating table for #{cl.name}..."
    cl.create_table
  end
end

app = SPQR::App.new(:loglevel => debug, :user => username, :password => password, :host => host, :port => port)
app.register Mrg::Grid::Config::Store,Mrg::Grid::Config::Node,Mrg::Grid::Config::Configuration,Mrg::Grid::Config::Feature,Mrg::Grid::Config::Group,Mrg::Grid::Config::Parameter,Mrg::Grid::Config::Subsystem

app.main
