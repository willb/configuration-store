#!/usr/bin/env ruby

# creates non-existent tables in a preexisting db.  utility only.

require 'spqr/spqr'
require 'spqr/app'

require 'mrg/grid/config'

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

classes = Mrg::Grid::Config::MAIN_DB_TABLES
classes.each do |cl| 
  puts "creating table for #{cl.name} if necessary..."
  cl.create_table rescue nil
end

