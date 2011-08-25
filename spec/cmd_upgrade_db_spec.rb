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
          @conv = {:Node=>:Node, :Group=>:Group, :Feature=>:Feature, :Parameter=>:Param, :Subsystem=>:Subsys}
          @setter_from_getter = {:memberships=>:modifyMemberships, :features=>:modifyFeatures, :params=>:modifyParams, :kind=>:setKind, :default=>:setDefault, :description=>:setDescription, :must_change=>:setMustChange, :visibility_level=>:setVisibilityLevel, :requires_restart=>:setRequiresRestart, :depends=>:modifyDepends, :conflicts=>:modifyConflicts, :included_features=>:modifyIncludedFeatures}
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
                    obj = @store.send("get#{@conv[type]}ByName", n)
                  else
                    obj = @store.send("get#{@conv[type]}", n)
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

        def get_store_contents
          Mrg::Grid::SerializedConfigs::ConfigSerializer.new(@store).serialize
        end

        def verify_store(old_store)
          cur_store = get_store_contents
          [:nodes, :groups, :params, :features, :subsystems].each do |type|
      
            cur_store.send(type).each do |obj|
              methods = obj.public_methods(false).select {|m| m.index("=") == nil}
              old_obj = old_store.send(type).select {|o| o.name == obj.name}[0]
              methods.each do |m|
                obj.send(m).should == old_obj.send(m)
              end
            end
          end
        end

        def change_expectations_then_patch(skip_patterns=[])
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
          [:modify, :delete].each do |changed|
            affected[changed].each do |type, names|
              names.each do |n|
                skip = false
                skip_patterns.each do |s|
                  if n.index(s) != nil
                    skip = true
                    break
                  end
                end
                if skip
                  next
                end
                @store.send("check#{type}Validity", n).should == []
                dets = patcher.entity_details(type, n)
                dets[:expected].each do |getter, value|
                  t = Time.now.utc
                  new_val = (t.tv_sec * 1000000) + t.tv_usec
                  if type == :Group
                    obj = @store.send("get#{@conv[type]}ByName", n)
                  else
                    obj = @store.send("get#{@conv[type]}", n)
                  end
                  obj.should_not == nil
                  getter = getter.intern
                  cmd = @setter_from_getter[getter]
                  if cmd.to_s =~ /^modifyParams/ and (type == :Feature or type == :Group)
                    obj.send(cmd, "REPLACE", {"EXTRA_PARAM"=>new_val}, {})
                  elsif cmd.to_s =~ /^modify/
                    if type == :Feature or type == :Group
                      obj.send(cmd, "REPLACE", [extra_feat], {})
                    elsif type == :Parameter
                      obj.send(cmd, "REPLACE", [extra_param], {})
                    elsif type == :Node
                      obj.send(cmd, "REPLACE", [extra_group], {})
                    else
                      # Subsystem
                      obj.send(cmd, "REPLACE", [extra_param], {})
                    end
                  else
                    obj.send(cmd, new_val)
                  end

                  state = get_store_contents
                  patch_db(1)
                  verify_store(state)
                  @store.loadSnapshot(snap_name)
                end
              end
            end
          end
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

        it "should fail on unexpected db changes when deleting" do
          @patch_files = ["#{File.dirname(__FILE__)}/db-patching-del-patch.yaml"]
          change_expectations_then_patch(["+++"])
        end

        it "should fail on unexpected db changes when updating" do
          @patch_files = ["#{File.dirname(__FILE__)}/db-patching-update-patch.yaml"]
          change_expectations_then_patch
        end

        it "should rollback the database on failure" do
          @patch_files = ["#{File.dirname(__FILE__)}/db-patching-del-patch.yaml"]
          patcher = Mrg::Grid::SerializedConfigs::PatchLoader.new(@store, false)

          patcher.load_yaml(open("#{@patch_files[0]}", "r") {|db| db.read})
          dets = patcher.entity_details(:Feature, "BaseDBVersion")
          expected_ver_str = dets[:expected]["params"]["BaseDBVersion"]
          tmp = expected_ver_str.split(".")
          major = tmp[0]
          minor = tmp[1].to_i
          obj = @store.getFeature("BaseDBVersion")
          obj.modifyParams("REPLACE", {"BaseDBVersion"=>"#{major}.#{minor+1}"}, {})
          @store.should_receive(:loadSnapshot)
          patch_db(1)
        end

        it "should handle missing DB version feature" do
          @patch_files = ["#{File.dirname(__FILE__)}/db-patching-del-patch.yaml"]
          @store.removeFeature("BaseDBVersion")
          patch_db
          verify_changes
        end

        it "should handle malformed DB version" do
          @patch_files = ["#{File.dirname(__FILE__)}/db-patching-del-patch.yaml"]
          bad_versions = ["invalid string", "1111111", ".1111", 11111, 0.1111]
          @store.makeSnapshot("Pre")
          obj = @store.getFeature("BaseDBVersion")

          bad_versions.each do |ver|
            @store.loadSnapshot("Pre")
            obj.modifyParams("REPLACE", {"BaseDBVersion"=>ver}, {})
            patch_db(0, ["-f"])
            verify_changes
          end

          @store.loadSnapshot("Pre")
          obj.modifyParams("REPLACE", {}, {})
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

        it "should patch anyway if force option used" do
          @patch_files = ["#{File.dirname(__FILE__)}/db-patching-del-patch.yaml"]
          obj = @store.getFeature("BaseDBVersion")
          obj.modifyParams("REPLACE", {"BaseDBVersion"=>"1.1"}, {})
          patch_db(1)
          patch_db(0, ["-f"])
          verify_changes
        end

        it "should not patch if the db version is >= patch verion" do
          @patch_files = ["#{File.dirname(__FILE__)}/db-patching-del-patch.yaml"]
          patcher = Mrg::Grid::SerializedConfigs::PatchLoader.new(@store, false)

          patcher.load_yaml(open("#{@patch_files[0]}", "r") {|db| db.read})
          tmp = patcher.db_version.to_s.split(".")
          major = tmp[0].delete("v").to_i
          minor = tmp[1].to_i
          @store.should_not_receive(:makeSnapshot)

          obj = @store.getFeature("BaseDBVersion")
          obj.modifyParams("REPLACE", {"BaseDBVersion"=>"#{major+1}.#{minor}"}, {})
          patch_db(0)

          obj.modifyParams("REPLACE", {"BaseDBVersion"=>"#{major}.#{minor}"}, {})
          patch_db(0)

          obj.modifyParams("REPLACE", {"BaseDBVersion"=>"#{major}.#{minor+1}"}, {})
          patch_db(0)
        end
      end
    end
  end
end
