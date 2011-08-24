require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'digest/md5'
require 'fileutils'
require 'mrg/grid/config/shell'

module Mrg
  module Grid
    module Config

      describe Store do
        before(:each) do
          setup_rhubarb
          @store = Store.new
          yaml_text = open("#{File.dirname(__FILE__)}/db-patching-basedb.yaml", "r") {|db| db.read}
          reconstitute_db(yaml_text)

          @wallaby_cmd = "upgrade-db"
          @patch_dir = "/tmp/db_patches"
          @affected = {}
          @versions = []
          @dets = Hash.new {|h,k| h[k] = Hash.new {|h1,k1| h1[k1] = {} } }
          @fconv = {:Node=>:Node, :Group=>:Group, :Feature=>:Feature, :Parameter=>:Param, :Subsystem=>:Subsys}
          @oconv = {:nodes=>:Node, :groups=>:Group, :params=>:Paramter, :features=>:Feature, :subsystems=>:Subsystem}
          @setters = {:memberships=>:modifyMemberships, :features=>:modifyFeatures, :params=>:modifyParams, :kind=>:setKind, :default=>:setDefault, :description=>:setDescription, :must_change=>:setMustChange, :visibility_level=>:setVisibilityLevel, :requires_restart=>:setRequiresRestart, :depends=>:modifyDepends, :conflicts=>:modifyConflicts, :included_features=>:modifyIncludedFeatures}
        end
        
        after(:each) do
          Dir.foreach(@patch_dir) do |f|
            if f != "." and f != ".."
              FileUtils.rm("#{@patch_dir}/#{f}")
            end
          end
          Dir.delete(@patch_dir)
          teardown_rhubarb
        end
        
        include BaseDBFixture
        
        def patch_db(expected_exit=0, cmd_args=[])
          patcher = Mrg::Grid::SerializedConfigs::PatchLoader.new(@store, false)
          Dir.mkdir(@patch_dir) rescue nil
          prev_f = ""
          @patch_files.each do |f|
            if f != "." and f != ".."
              FileUtils.cp(f, @patch_dir)
              filename = "#{@patch_dir}/#{File.basename(f)}"
              if prev_f != ""
                prev_v, next_v = setup_to_trail(prev_f, filename)
                @versions = @versions + ([prev_v, next_v] - @versions)
              end
              prev_f = filename
            end
          end
          Mrg::Grid::Config::Shell::Upgrade_db.new(@store, "").main(["-d", "#{@patch_dir}"] + cmd_args).should == expected_exit
          @patch_files.each do |f|
            patcher.load_yaml(open("#{f}", "r") {|db| db.read})
            new = patcher.affected_entities
            @affected.merge!(new)
            new.keys.each do |changed|
              new[changed].each do |type, names|
                names.each do |n|
                  @dets[type][n].merge!(patcher.entity_details(type, n))
                end
              end
            end
          end
        end

        def verify_changes
          @affected.keys.each do |changed|
            @affected[changed].each do |type, names|
              names.each do |n|
                if changed == :delete
                  @store.send("check#{type}Validity", n).should == [n]
                else
                  @store.send("check#{type}Validity", n).should == []
                  if type == :Group
                    obj = @store.send("get#{@fconv[type]}ByName", n)
                  else
                    obj = @store.send("get#{@fconv[type]}", n)
                  end
                  obj.should_not == nil
                  @dets[type][n][:updates].each do |get, value|
                    obj.send(get).should == value
                  end
                end
              end
            end
          end
        end

        def setup_to_trail(prev, nextf)
          reader = Mrg::Grid::SerializedConfigs::PatchLoader.new(@store, false)
          reader.load_yaml(open("#{prev}", "r") {|db| db.read})
          ver1 = reader.db_version
          fhdl = open(nextf, 'r')
          contents = ""
          old = 0
          fhdl.read.each do |line|
            if line =~ /BaseDBVersion:\s*v(.+)$/
              if old == 0
                old = $1
              end
            end
            contents += line
          end
          fhdl.close
          fhdl = open(nextf, 'w')
          ver2 = 0
          contents.each do |line|
            if line =~ /^db_version:\s*"(.*)"$/
              ver2 = $1
            end
            if line =~ /(.*)BaseDBVersion:(\s*)v#{old}/
              fhdl.write("#{$1}BaseDBVersion:#{$2}v#{ver1}")
            else
              fhdl.write(line)
            end
          end
          fhdl.close
          [ver1, ver2]
        end

        it "should remove entities from the store" do
          @patch_files = ["#{File.dirname(__FILE__)}/db-patching-del-patch.yaml"]
          patch_db
          verify_changes
        end

        it "should add entities to the store" do
          @patch_files = ["#{File.dirname(__FILE__)}/db-patching-add-patch.yaml"]
          patch_db
          verify_changes
        end

        it "should update entities in the store" do
          @patch_files = ["#{File.dirname(__FILE__)}/db-patching-update-patch.yaml"]
          patch_db
          verify_changes
        end

        it "should create a snapshot for each patch file from the db version in the file" do
          @patch_files = ["#{File.dirname(__FILE__)}/db-patching-del-patch.yaml", "#{File.dirname(__FILE__)}/db-patching-add-patch.yaml"]
          Snapshot.count.should == 0
          patch_db
          verify_changes
          Snapshot.count.should == 2
          found_all = true
          @versions.each do |v|
            found = false
            Snapshot.find_all.each do |snap|
              if snap.name =~ /.*#{v}.*/
                found = true
              end
            end
            found_all = found_all and found
          end
          found_all.should == true
        end

        it "should fail on unexpected db changes when deleteing and load pre-upgrade snapshot" do
          @patch_files = ["#{File.dirname(__FILE__)}/db-patching-del-patch.yaml"]
          patcher = Mrg::Grid::SerializedConfigs::PatchLoader.new(@store, false)
          snap_name = "Pre-Change"
          extra_feat = "ExtraFeature"
          extra_group = "ExtraGroup"
          extra_param = "EXTRA_PARAM"

          @store.addFeature(extra_feat)
          @store.addExplicitGroup(extra_group)
          @store.makeSnapshot(snap_name)

          patcher.load_yaml(open("#{@patch_files[0]}", "r") {|db| db.read})
          affected = patcher.affected_entities
          totals = 0
          affected.keys.each do |changed|
            affected[changed].each do |type, names|
              totals += names.count
            end
          end
          @store.should_receive(:loadSnapshot).exactly(totals*2).times
          affected.keys.each do |changed|
            affected[changed].each do |type, names|
              names.each do |n|
                @store.send("check#{type}Validity", n).should == []
                dets = patcher.entity_details(type, n)
                dets[:expected].each do |getter, value|
#                  puts "name = #{n}"
                  t = Time.now.utc
                  new_val = (t.tv_sec * 1000000) + t.tv_usec
                  if type == :Group
                    obj = @store.send("get#{@fconv[type]}ByName", n)
                  else
                    obj = @store.send("get#{@fconv[type]}", n)
                  end
                  obj.should_not == nil
                  getter = getter.intern
                  cmd = @setters[getter]
#                  puts "type = #{type}"
#                  puts "cmd = #{cmd}"
#                  puts "original val = #{obj.send(getter).inspect}"
                  if cmd.to_s =~ /^modifyParams/ and (type == :Feature or type == :Group)
                    obj.send(@setters[getter], "REPLACE", {"EXTRA_PARAM"=>new_val}, {})
                    puts obj.params.inspect
                  elsif cmd.to_s =~ /^modify/
                    if type == :Feature or type == :Group
                      obj.send(@setters[getter], "REPLACE", [extra_feat], {})
                    elsif type == :Parameter
                      obj.send(@setters[getter], "REPLACE", [extra_param], {})
                    elsif type == :Node
                      obj.send(@setters[getter], "REPLACE", [extra_group], {})
                    else
                      # Subsystem
                      obj.send(@setters[getter], "REPLACE", [extra_param], {})
                      puts obj.params.inspect
                    end
                  else
                    obj.send(@setters[getter], new_val)
                  end

                  patch_db(1)
#                  puts "loading pre-patch snapshot"
                  @store.loadSnapshot(snap_name)
#                  puts "loaded pre-patch snapshot"
                end
              end
            end
          end
        end

#        it "should fail on unexpected db changes when adding and load pre-upgrade snapshot" do
#        end

#        it "should fail on unexpected db changes when updating and load pre-upgrade snapshot" do
#        end

#        it "should handle missing DB version feature" do
#          @patch_files = ["#{File.dirname(__FILE__)}/db-patching-del-patch.yaml"]
#          @store.removeFeature("BaseDBVersion")
#          patch_db
#          verify_changes
#        end

        it "should handle malformed DB version" do
          @patch_files = ["#{File.dirname(__FILE__)}/db-patching-del-patch.yaml"]
          @store.makeSnapshot("Pre")
          obj = @store.getFeature("BaseDBVersion")

          obj.modifyParams("REPLACE", {"BaseDBVersion"=>"invalid string"}, {})
          patch_db(0, ["-f"])
          verify_changes

          @store.loadSnapshot("Pre")
          obj.modifyParams("REPLACE", {"BaseDBVersion"=>"1111111"}, {})
          patch_db(0, ["-f"])
          verify_changes

          @store.loadSnapshot("Pre")
          obj.modifyParams("REPLACE", {"BaseDBVersion"=>".1111"}, {})
          patch_db(0, ["-f"])
          verify_changes

          @store.loadSnapshot("Pre")
          obj.modifyParams("REPLACE", {}, {})
          patch_db(0, ["-f"])
          verify_changes

          @store.loadSnapshot("Pre")
          obj.modifyParams("REPLACE", {"EXTRA_PARAM"=>"231231231"}, {})
          patch_db(0, ["-f"])
          verify_changes
        end

        it "should handle DB versions with and without a v" do
          @patch_files = ["#{File.dirname(__FILE__)}/db-patching-del-patch.yaml"]
          @store.makeSnapshot("Pre")
          obj = @store.getFeature("BaseDBVersion")

          ver = obj.params["BaseDBVersion"]
          ver.delete!("v")
          obj.modifyParams("REPLACE", {"BaseDBVersion"=>ver}, {})
          patch_db(0, ["-f"])
          verify_changes

          @store.loadSnapshot("Pre")
          ver = obj.params["BaseDBVersion"]
          if not ver.include?("v")
            ver.insert(0, "v")
            obj.modifyParams("REPLACE", {"BaseDBVersion"=>ver}, {})
          end 
          patch_db(0, ["-f"])
          verify_changes
        end

#        it "should patch anyway if force option used" do
#        end

#        if "should not patch if the db version is <= patch verion" do
#        end

      end
    end
  end
end
