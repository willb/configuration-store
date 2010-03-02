#!/usr/bin/env ruby

# create-tables.rb:  creates non-existent tables in a preexisting db.  development utility only.
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

