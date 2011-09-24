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

          @args = {:dir=>"/tmp/db_patches"}
        end
        
        after(:each) do
          dir = @args[:dir]
          Dir.foreach(dir) do |f|
            if f != "." and f != ".."
              FileUtils.rm("#{dir}/#{f}")
            end
          end
          Dir.delete(dir)
          teardown_rhubarb
        end
        
        include BaseDBFixture
        include PatchTester
        
        it "should remove entities from the store" do
          @args[:files] = ["#{File.dirname(__FILE__)}/db-1.5.wpatch"]
          verify_changes(*patch_db(@args))
        end

        it "should add entities to the store" do
          @args[:files] = ["#{File.dirname(__FILE__)}/db-1.6.wpatch"]
          verify_changes(*patch_db(@args))
        end

        it "should update entities in the store" do
          @args[:files] = ["#{File.dirname(__FILE__)}/db-1.7.wpatch"]
          verify_changes(*patch_db(@args))
        end

        it "should create a snapshot for each patch file from the db version in the file" do
          @args[:files] = ["#{File.dirname(__FILE__)}/db-1.5.wpatch", "#{File.dirname(__FILE__)}/db-1.6.wpatch"]
          Snapshot.count.should == 0
          verify_changes(*patch_db(@args))
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
          @args[:files] = ["#{File.dirname(__FILE__)}/db-1.5.wpatch"]
          @args[:skip_patterns] = ["+++"]
          @args[:exit_code] = 1
          change_expectations_then_patch(@args)
        end

        it "should fail on unexpected db changes when updating" do
          @args[:files] = ["#{File.dirname(__FILE__)}/db-1.7.wpatch"]
          @args[:exit_code] = 1
          change_expectations_then_patch(@args)
        end

        it "should rollback the database on failure" do
          @args[:files] = ["#{File.dirname(__FILE__)}/db-1.5.wpatch"]
          @args[:exit_code] = 1
          patcher = Mrg::Grid::PatchConfigs::PatchLoader.new(@store, false)

          patcher.load_yaml(open("#{@args[:files][0]}", "r") {|db| db.read})
          dets = patcher.entity_details(:Feature, "BaseDBVersion")
          expected_ver_str = dets[:expected]["params"]["BaseDBVersion"]
          tmp = expected_ver_str.split(".")
          major = tmp[0]
          minor = tmp[1].to_i
          obj = @store.getFeature("BaseDBVersion")
          obj.modifyParams("REPLACE", {"BaseDBVersion"=>"#{major}.#{minor+1}"}, {})
          @store.should_receive(:loadSnapshot)
          patch_db(@args)
        end

        it "should handle missing DB version feature" do
          @args[:files] = ["#{File.dirname(__FILE__)}/db-1.5.wpatch"]
          @store.removeFeature("BaseDBVersion")
          verify_changes(*patch_db(@args))
        end

        it "should handle malformed DB version" do
          @args[:files] = ["#{File.dirname(__FILE__)}/db-1.5.wpatch"]
          @args[:cmd_args] = ["-f"]
          bad_versions = ["invalid string", "1111111", ".1111", 11111, 0.1111]

          @store.makeSnapshot("Pre")
          obj = @store.getFeature("BaseDBVersion")

          bad_versions.each do |ver|
            @store.loadSnapshot("Pre")
            obj.modifyParams("REPLACE", {"BaseDBVersion"=>ver}, {})
            verify_changes(*patch_db(@args))
          end

          @store.loadSnapshot("Pre")
          obj.modifyParams("REPLACE", {}, {})
          verify_changes(*patch_db(@args))
        end

        it "should handle DB versions with and without a v" do
          @args[:files] = ["#{File.dirname(__FILE__)}/db-1.5.wpatch"]
          @args[:cmd_args] = ["-f"]
          @store.makeSnapshot("Pre")
          obj = @store.getFeature("BaseDBVersion")

          ver = obj.params["BaseDBVersion"]
          ver.delete!("v")
          obj.modifyParams("REPLACE", {"BaseDBVersion"=>ver}, {})
          verify_changes(*patch_db(@args))

          @store.loadSnapshot("Pre")
          ver = obj.params["BaseDBVersion"]
          if not ver.include?("v")
            ver.insert(0, "v")
            obj.modifyParams("REPLACE", {"BaseDBVersion"=>ver}, {})
          end 
          verify_changes(*patch_db(@args))
        end

        it "should patch anyway if force option used" do
          @args[:files] = ["#{File.dirname(__FILE__)}/db-1.5.wpatch"]
          @args[:exit_code] = 1

          obj = @store.getFeature("BaseDBVersion")
          obj.modifyParams("REPLACE", {"BaseDBVersion"=>"1.1"}, {})
          patch_db(@args)
          @args[:exit_code] = 0
          @args[:cmd_args] = ["-f"]
          verify_changes(*patch_db(@args))
        end

        it "should not patch if the db version is >= patch verion" do
          @args[:files] = ["#{File.dirname(__FILE__)}/db-1.5.wpatch"]
          patcher = Mrg::Grid::PatchConfigs::PatchLoader.new(@store, false)

          patcher.load_yaml(open("#{@args[:files][0]}", "r") {|db| db.read})
          tmp = patcher.db_version.to_s.split(".")
          major = tmp[0].delete("v").to_i
          minor = tmp[1].to_i
          @store.should_not_receive(:makeSnapshot)

          obj = @store.getFeature("BaseDBVersion")

          [[major+1, minor], [major, minor], [major, minor+1]].each do |ma, mi|
            obj.modifyParams("REPLACE", {"BaseDBVersion"=>"#{ma}.#{mi}"}, {})
            contents = get_store_contents
            patch_db(@args)
            verify_store(contents)
          end
        end
      end
    end
  end
end
