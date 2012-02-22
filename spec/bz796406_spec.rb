require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'digest/md5'

module Mrg
  module Grid
    module Config

      describe Node do
        before(:each) do
          setup_rhubarb
          @store = Store.new
          reconstitute_db
        end
        
        after(:each) do
          teardown_rhubarb
        end
        
        include BaseDBFixture
        
        it "should consider group deletion to be a configuration change for nodes" do
          node = @store.addNode("test")
          group = @store.addExplicitGroup("group1")
          @store.addParam("PARAM1")
          group.modifyParams("ADD", {"PARAM1"=>"value1"}, {})
          node.modifyMemberships("ADD", %w{group1}, {})
          @store.activateConfiguration

          old_version = node.getConfig()["WALLABY_CONFIG_VERSION"]

          @store.removeGroup("group1")
          @store.activateConfiguration

          new_version = node.getConfig()["WALLABY_CONFIG_VERSION"]

          new_version.should_not == old_version

          node.getConfig().keys.should_not include("PARAM1")
        end
      end
    end
  end
end
