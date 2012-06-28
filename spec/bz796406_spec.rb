require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'digest/md5'

module Mrg
  module Grid
    module Config
      describe Node do
        before(:each) do
          setup_rhubarb
          @store = Store.new
        end
        
        after(:each) do
          teardown_rhubarb
        end
        
        it "should recognize node configuration change after group delete" do
          node = @store.addNode("node1")
          @store.addParam("param1")
          group = @store.addExplicitGroup("group1")
          group.modifyParams("REPLACE", {"param1"=>"value"}, {})
          node.modifyMemberships("REPLACE", "group1", {})
          @store.activateConfiguration()
          ver = node.getConfig({})["WALLABY_CONFIG_VERSION"]
          @store.removeGroup("group1")
          @store.activateConfiguration()
          config = node.getConfig({})
          config.keys.should_not include "param1"
          config["WALLABY_CONFIG_VERSION"].should_not == ver
        end
      end
    end
  end
end
