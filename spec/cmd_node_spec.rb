require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'digest/md5'
require 'mrg/grid/config/shell'
require 'tempfile'

module Mrg
  module Grid
    module Config

      describe Store do
        before(:each) do
          setup_rhubarb
          @store = Store.new

          @store.addParam("p1")
          @store.addParam("p2")
          f = @store.addFeature("f1")
          f.modifyParams("REPLACE", {"p1"=>1}, {})

          @store.addNode("n1")
        end
        
        after(:each) do
          teardown_rhubarb
        end
        
        def show_config(ver=nil)
          old = $stdout
          out_file = Tempfile.new("cmd_node_spec")
          $stdout = out_file
          args = ["n1"]
          args += ["-l", ver.to_s] if ver
          Mrg::Grid::Config::Shell::ShowNodeConfig.new(@store, "").main(args)
          $stdout = old
          out_file.flush
          out_file.seek(0, IO::SEEK_SET)
          out_file.read
        end

        it "should show a node's current config" do
          n = @store.getNode("n1")
          n.identity_group.modifyFeatures("REPLACE", ["f1"], {})
          n.identity_group.modifyParams("REPLACE", {"p2"=>2}, {})

          output = show_config
          output.should include "config:"
          output.should include '"p1"=>"1"'
          output.should include '"p2"=>"2"'
          output.should include '"WALLABY_CONFIG_VERSION"=>"0"'
        end

        it "should show the most recent config no newer than version provided" do
          @store.getNode("n1").identity_group.modifyFeatures("REPLACE", ["f1"], {})
          @store.activateConfiguration
          v1 = @store.getNode("n1").last_updated_version

          @store.getNode("n1").identity_group.modifyParams("REPLACE", {"p2"=>2}, {})
          @store.activateConfiguration
          v2 = @store.getNode("n1").last_updated_version

          output = show_config(0)
          output.should include "config:"
          output.should include '"WALLABY_CONFIG_VERSION"=>"0"'
          output.should_not include '"p1"=>"1"'
          output.should_not include '"p2"=>"2"'

          output = show_config(v1)
          output.should include "config:"
          output.should include '"p1"=>"1"'
          output.should include "\"WALLABY_CONFIG_VERSION\"=>\"#{v1}\""
          output.should_not include '"p2"=>"2"'

          output = show_config(v2)
          output.should include "config:"
          output.should include '"p1"=>"1"'
          output.should include '"p2"=>"2"'
          output.should include "\"WALLABY_CONFIG_VERSION\"=>\"#{v2}\""
        end

      end
    end
  end
end
