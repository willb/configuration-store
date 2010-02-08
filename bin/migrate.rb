#!/usr/bin/env ruby

# Performs migrations as necessary to bring a db up to date (primarily
# intended for development, as there are some painful downsides to in-place db
# migration).  The right approach for db migrations is to dump and load the
# store over QMF.

require 'spqr/spqr'
require 'spqr/app'

require 'mrg/grid/config'
require 'fileutils'

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

FileUtils.cp(dbname,"#{dbname}.bck")

Rhubarb::Persistence::open(dbname)

classes = Mrg::Grid::Config::MAIN_DB_TABLES
classes.each do |cl| 
  puts "creating table for #{cl.name} if necessary..."
  cl.create_table rescue nil
end

observed_version = Rhubarb::Persistence::db.get_first_value("PRAGMA user_version").to_i
version = observed_version

Mrg::Grid::Config::DBMIGRATIONS.slice(observed_version + 1, Mrg::Grid::Config::DBMIGRATIONS.size).each do |migration|
  puts "bringing db up to version #{observed_version + 1}"
  migration.call
  observed_version = Rhubarb::Persistence::db.get_first_value("PRAGMA user_version").to_i
  puts "db is at version #{observed_version}"
end