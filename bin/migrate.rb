#!/usr/bin/env ruby

# migrate.rb
# Performs migrations as necessary to bring a db up to date (primarily
# intended for development, as there are some painful downsides to in-place db
# migration).  The right approach for db migrations is to dump and load the
# store over QMF.
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