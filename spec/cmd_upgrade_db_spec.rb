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
        
        it "should remove entities from the store" do
          patch_file = "#{File.dirname(__FILE__)}/db-patching-del-patch.yaml"
          Dir.mkdir(@patch_dir)
          FileUtils.cp(patch_file, @patch_dir)
#	  Mrg::Grid::Config::Shell::main(["#{@wallaby_cmd}", "-d", "#{patch_dir}"])
          lambda { Mrg::Grid::Config::Shell::Upgrade_db.new(@store, "").main(["-d", "#{@patch_dir}"]) }.should_not raise_error
          patch = Mrg::Grid::SerializedConfigs::PatchLoader.new(@store, false)
          patch.load_yaml(open("#{patch_file}", "r") {|db| db.read})
          affected = patch.affected_entities
          puts "affected: #{affected.inspect}"
          failed = false
          failures = Hash.new {|h,k| h[k] = [] }
          affected["delete"].each do |type, names|
            names.each do |n|
              if type == :Group
                cmd = "getGroupByName"
              else
                cmd = "get#{type}"
              end
              lambda { @store.send(cmd, n) }.should raise_error
#              if @store.send(cmd, n) != []
#                failed = true
#                failures[type].push(n)
#              end
            end
          end

#          if failed 
#            puts "Found in store but shouldn't exist:"
#            puts failures.inspect
#            failures.should equal []
#          end
        end
      end
    end
  end
end
