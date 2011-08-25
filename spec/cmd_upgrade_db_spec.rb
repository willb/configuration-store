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

          @patch_dir = "/tmp/db_patches"
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
        include PatchTester
        
        it "should remove entities from the store" do
          @patch_files = ["#{File.dirname(__FILE__)}/db-patching-del-patch.yaml"]
          verify_changes(*patch_db)
        end

        it "should add entities to the store" do
          @patch_files = ["#{File.dirname(__FILE__)}/db-patching-add-patch.yaml"]
          verify_changes(*patch_db)
        end

        it "should update entities in the store" do
          @patch_files = ["#{File.dirname(__FILE__)}/db-patching-update-patch.yaml"]
          verify_changes(*patch_db)
        end

        it "should create a snapshot for each patch file from the db version in the file" do
          @patch_files = ["#{File.dirname(__FILE__)}/db-patching-del-patch.yaml", "#{File.dirname(__FILE__)}/db-patching-add-patch.yaml"]
          Snapshot.count.should == 0
          verify_changes(*patch_db)
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
          verify_changes(*patch_db)
        end

        it "should handle malformed DB version" do
          @patch_files = ["#{File.dirname(__FILE__)}/db-patching-del-patch.yaml"]
          bad_versions = ["invalid string", "1111111", ".1111", 11111, 0.1111]
          @store.makeSnapshot("Pre")
          obj = @store.getFeature("BaseDBVersion")

          bad_versions.each do |ver|
            @store.loadSnapshot("Pre")
            obj.modifyParams("REPLACE", {"BaseDBVersion"=>ver}, {})
            verify_changes(*patch_db(0, ["-f"]))
          end

          @store.loadSnapshot("Pre")
          obj.modifyParams("REPLACE", {}, {})
          verify_changes(*patch_db(0, ["-f"]))
        end

        it "should handle DB versions with and without a v" do
          @patch_files = ["#{File.dirname(__FILE__)}/db-patching-del-patch.yaml"]
          @store.makeSnapshot("Pre")
          obj = @store.getFeature("BaseDBVersion")

          ver = obj.params["BaseDBVersion"]
          ver.delete!("v")
          obj.modifyParams("REPLACE", {"BaseDBVersion"=>ver}, {})
          verify_changes(*patch_db(0, ["-f"]))

          @store.loadSnapshot("Pre")
          ver = obj.params["BaseDBVersion"]
          if not ver.include?("v")
            ver.insert(0, "v")
            obj.modifyParams("REPLACE", {"BaseDBVersion"=>ver}, {})
          end 
          verify_changes(*patch_db(0, ["-f"]))
        end

        it "should patch anyway if force option used" do
          @patch_files = ["#{File.dirname(__FILE__)}/db-patching-del-patch.yaml"]
          obj = @store.getFeature("BaseDBVersion")
          obj.modifyParams("REPLACE", {"BaseDBVersion"=>"1.1"}, {})
          patch_db(1)
          verify_changes(*patch_db(0, ["-f"]))
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
