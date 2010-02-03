#!/usr/bin/env ruby

require 'spqr/spqr'
require 'spqr/app'

require 'configstore/mrg/grid/config'

dbname = ":memory:"
snapdb = ":memory:"
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
  
  opts.on("-s", "--snapdb FILE", "file for store snapshots (will be created if it doesn't exist)") do |db|
    snapdb = db
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
puts "storing snapshots to #{snapdb}"
DO_CREATE = (dbname == ":memory:" or not File.exist?(dbname))
DO_SNAPCREATE = (snapdb == ":memory:" or not File.exist?(snapdb))

Rhubarb::Persistence::open(dbname)
Rhubarb::Persistence::open(snapdb,:snapshot)

Mrg::Grid::Config::MAIN_DB_TABLES.each {|tab| tab.db = Rhubarb::Persistence::dbs[:default] }
Mrg::Grid::Config::Snapshot.db = Rhubarb::Persistence::dbs[:snapshot]

if DO_CREATE
  classes = Mrg::Grid::Config::MAIN_DB_TABLES
  classes.each do |cl| 
    puts "creating table for #{cl.name}..."
    cl.create_table
  end
  Mrg::Grid::Config::Store.find_by_id(0).storeinit
end

if DO_SNAPCREATE
  puts "creating snapshot table"
  Mrg::Grid::Config::Snapshot.create_table(:snapshot)
end

options = {}
options[:loglevel] = debug
options[:user] = username if username
options[:password] = password if password
options[:host] = host
options[:port] = port

app = SPQR::App.new(options)
app.register Mrg::Grid::Config::Store,Mrg::Grid::Config::Node,Mrg::Grid::Config::Configuration,Mrg::Grid::Config::Feature,Mrg::Grid::Config::Group,Mrg::Grid::Config::Parameter,Mrg::Grid::Config::Subsystem,Mrg::Grid::Config::Snapshot

app.main
