#!/usr/bin/env ruby

# document-db.rb
#
# Copyright (c) 2012 Red Hat, Inc.
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

require 'mrg/grid/config-proxies'

@options = {}

op = OptionParser.new do |opts|
  opts.banner = "Usage document-db.rb [options]"
  
  opts.on("-f", "--dbfile FILE", "file with YAML dump of database") do |db| 
    dbname = db
  end

  opts.on("-o", "--output-dir DIR", "directory in which to place output") do |dir|
    @options[:basepath] = dir
  end

  opts.on("-b", "--base-uri URI", "base URI for generated documentation") do |dir|
    @options[:baseuri] = dir
  end
end

begin
  op.parse!
rescue OptionParser::InvalidOption
  puts op
  exit
end

dd = Mrg::Grid::SerializedConfigs::DatabaseDocumenter.new(open('spec/base-db.yaml') {|f| f.read}, @options)
dd.document_all
