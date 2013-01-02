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
        
        it "should validate configurations that set must-change parameters differing only by case" do
          node = @store.getNode("foo")
          group = @store.addExplicitGroup("dedicated-resources")
          group.modifyFeatures("ADD", ["DedicatedResource", "Master", "NodeAccess"], {})
          group.modifyParams("ADD", {"DedicatedScheduler"=>"DedicatedScheduler@blah.local.", "ALLOW_READ"=>"*", "ALLOW_WRITE"=>"*", "CONDOR_HOST"=>"blah.local."}, {})
          node.modifyMemberships("ADD", [group.name], {})
          @store.activateConfiguration.should == [{}, []]
        end
      end
    end
  end
end
