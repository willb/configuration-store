#!/usr/bin/ruby

require 'rubygems'
require 'grit'
require 'yaml'
require 'mrg/grid/config'

include Grit

class Database
  include Mrg::Grid::SerializedConfigs::DBHelpers

  def initialize(yml, db_ver)
    data = YAML::parse(yml).transform

    @nodes = dictify(data.nodes)
    @groups = dictify(data.groups)
    @params = dictify(data.params)
    @features = dictify(data.features)
    @subsystems = dictify(data.subsystems)
    @version = db_ver
  end

  def generate_patch(db_obj)
    @patch = Mrg::Grid::SerializedConfigs::Patch.new
    @patch.expected = Mrg::Grid::SerializedConfigs::Store.new
    @patch.updates = Mrg::Grid::SerializedConfigs::Store.new
    @patch.db_version = @version
    diff_nodes(db_obj.nodes)
    diff_groups(db_obj.groups)
    diff_params(db_obj.params)
    diff_features(db_obj.features)
    diff_subsystems(db_obj.subsystems)
    diff_versions(db_obj.version)
    @patch
  end

  def nodes
    @nodes
  end

  def groups
    @groups
  end

  def params
    @params
  end

  def features
    @features
  end

  def subsystems
    @subsystems
  end

  def version
    @version
  end

  private
  def make_patch_entity(new, old, methods)
    updates = Hash.new {|h,k| h[k] = Hash.new {|h1,k1| h1[k1] = {} } }
    expected = Hash.new {|h,k| h[k] = Hash.new {|h1,k1| h1[k1] = {} } }
    new.each do |name, obj|
      methods.each do |get, qmfget, set|
        if not old.has_key?(name) or obj.send(get) != old[name].send(get)
          if set.to_s =~ /^modify/
            updates[name].merge!({"#{set}"=>["REPLACE", obj.send(get), {}]})
          else
            updates[name].merge!({"#{set}"=>obj.send(get)})
          end
          if old.has_key?(name)
            expected[name].merge!({"#{qmfget}"=>old[name].send(get)})
          end
        end
      end
    end
    old.each do |name, obj|
      if not new.has_key?(name)
        methods.each do |get, qmfget, set|
          expected[name].merge!({"#{qmfget}"=>old[name].send(get)})
        end
      end
    end
    return updates, expected
  end

  def diff_nodes(old_nodes)
    @patch.updates.nodes, @patch.expected.nodes = make_patch_entity(@nodes, old_nodes, [[:membership, :memberships, :modifyMemberships]])
  end

  def diff_groups(old_groups)
    @patch.updates.groups, @patch.expected.groups = make_patch_entity(@groups, old_groups, [[:features, :features, :modifyFeatures], [:params, :params, :modifyParams]])
  end

  def diff_params(old_params)
    @patch.updates.params, @patch.expected.params = make_patch_entity(@params, old_params, [[:kind, :kind, :setKind], [:default_val, :default, :setDefault], [:description, :description, :setDescription], [:must_change, :must_change, :setMustChange], [:level, :visibility_level, :setVisibilityLevel], [:needs_restart, :requires_restart, :setRequiresRestart], [:depends, :depends, :modifyDepends], [:conflicts, :conflicts, :modifyConflicts]])
  end

  def diff_features(old_features)
    @patch.updates.features, @patch.expected.features = make_patch_entity(@features, old_features, [[:params, :params, :modifyParams], [:included, :included_features, :modifyIncludedFeatures], [:conflicts, :conflicts, :modifyConflicts], [:depends, :depends, :modifyDepends]])
  end

  def diff_subsystems(old_subsystems)
    @patch.updates.subsystems, @patch.expected.subsystems = make_patch_entity(@subsystems, old_subsystems, [[:params, :params, :modifyParams]])
  end

  def diff_versions(old_version)
    old_split = old_version.split(".")
    old_maj = old_split[0].to_i
    old_min = old_split[1].to_i

    new_split = @version.split(".")
    new_maj = new_split[0].to_i
    new_min = new_split[1].to_i

    if old_maj > 1 or (old_maj >= 1 and old_min > 4)
       @patch.expected.features["BaseDBVersion"] = {:params=>{"BaseDBVersion"=>"#{old_version.to_s}"}}
    end
    if new_maj > 1 or (new_maj >= 1 and new_min > 4)
       @patch.updates.features["BaseDBVersion"] = {"modifyParams"=>["REPLACE", {"BaseDBVersion"=>"v#{version.to_s}"}, {}]}
    end
  end
end

#repo = Repo.new("git://git.fedorahosted.org/git/grid/wallaby.git")
repo = Repo.new("..")
tags = repo.tags()
db_tags = []
tags.each do |t|
  if t.name =~ /DB-RELEASE-/
    db_tags.push(t)
  end

end
db_tags.sort! {|x, y| y.name =~ /DB-RELEASE-(\d+)\.(\d+)/
                      y_maj = $1.to_i
                      y_min = $2.to_i
                      x.name =~ /DB-RELEASE-(\d+)\.(\d+)/
                      x_maj = $1.to_i
                      x_min = $2.to_i
                      (x_maj > y_maj) or (x_maj <=> y_maj and x_min <=> y_min)}

old = nil
new = nil
diffs = {}
count = 0
db_tags.each do |t|
#  puts t.name
#  puts t.commit.id
  index = repo.index()
#  puts index.inspect
  tree = index.read_tree(t.commit.id)
#  puts tree.inspect
  begin
    content = tree/'condor-base-db.snapshot.in'
    if content == nil
      # Older form
      content = tree/'condor-base-db.snapshot'
    end
    t.name =~ /DB-RELEASE-([\d\.]+)/
    ver = $1
    old = new
    new = Database.new(content.data, ver)
    if count > 0
      patch = new.generate_patch(old)
      File.open(ver, "w") do |of|
        of.write(patch.to_yaml)
      end
    end
    count += 1
  end
end

f = open("../spec/db-patching-basedb.yaml", 'r') {|c| c.read}
old = Database.new(f, "1.0")
f = open("../spec/update.yaml", 'r') {|c| c.read}
new = Database.new(f, "1.7")
patch = new.generate_patch(old)
File.open("upgrade-patch.yaml", "w") do |of|
  of.write(patch.to_yaml)
end
