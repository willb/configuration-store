#!/usr/bin/ruby
#
# Copyright (c) 2011 Red Hat, Inc.
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

require 'rubygems'
require 'grit'
require 'mrg/grid/config-patches'

include Grit

class DiffGenerator
  def self.find_repo
    dir = "./"
    while not File.exists?("#{dir}/.git")
      dir += "../"
    end
    dir
  end

  def self.main(args)
    debug = false
    op = OptionParser.new do |opts|
      opts.on("-d", "--debug", "enable debug logging") do
        debug = true
      end
    end
    op.parse!
    repo_dir = find_repo
    patch_dir = "#{repo_dir}/patches"
    repo = Repo.new(repo_dir)
    tags = repo.tags()
    db_tags = []
    tags.each do |t|
      if t.name =~ /^DB-RELEASE-/
        db_tags.push(t)
      end
    end
    db_tags.sort! {|x, y| Mrg::Grid::PatchConfigs::DBVersion.new(x.name) <=> Mrg::Grid::PatchConfigs::DBVersion.new(y.name) }

    old = nil
    new = nil
    diffs = {}
    count = 0
    Dir.mkdir(patch_dir) rescue nil
    db_tags.each do |t|
      puts "Tag name: #{t.name}" if debug
      puts "Tag commit id: #{t.commit.id}" if debug
      index = repo.index()
      puts "Repo index: #{index.inspect}" if debug
      tree = index.read_tree(t.commit.id)
      puts "Index tree: #{tree.inspect}" if debug
      begin
        content = tree/'condor-base-db.snapshot.in'
        if content == nil
          # Older form
          content = tree/'condor-base-db.snapshot'
        end
        t.name =~ /DB-RELEASE-([\d\.]+)/
        ver = $1
        old = new
        new = Mrg::Grid::PatchConfigs::Database.new(content.data, ver)
        if count > 0
          patch = new.generate_patch(old)
          filename = "#{patch_dir}/db-#{ver}.wpatch"
          puts "Generating patch file #{filename}"
          File.open(filename, "w") do |of|
            of.write(patch.to_yaml)
          end
        end
        count += 1
      end
    end
  end
end
DiffGenerator::main(ARGV)
