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
        
        {"provisioned"=>:getNode, "unprovisioned"=>:addNode}.each do |kind,msg|

          it "should place new #{kind} nodes in the skeleton group" do
            n = @store.send(msg, "fake")
            n.memberships.should include(Group::SKELETON_GROUP_NAME)
          end

          ["when another node exists at activation", "when no other nodes exist at activation"].each do |dowhen|
            it "should give new #{kind} nodes the last-activated configuration for the skeleton group #{dowhen}" do
              @store.addParam("FOO")
              n_expected = @store.addNode("blah") if dowhen == "when another node exists at activation"
              g = @store.getGroupByName(Group::SKELETON_GROUP_NAME)
              g.modifyParams("REPLACE", {"FOO"=>"BAR"})
              @store.activateConfiguration
              g.modifyParams("REPLACE", {"FOO"=>"BLAH"})
            
              n = @store.send(msg, "fake")
              n.getConfig("version"=>::Rhubarb::Util::timestamp)["FOO"].should == "BAR"
            end
          end

          
        end

        it "should not place preexisting nodes in the skeleton group when provisioning them" do
          n = @store.getNode("fake")
          n.modifyMemberships("REPLACE", [], {})
          n = @store.addNode("fake")
          n.memberships.should_not include(Group::SKELETON_GROUP_NAME)
        end
        
        

        it "should publish the skeleton group over the API" do
          @store.getSkeletonGroup.name.should == Group::SKELETON_GROUP_NAME
        end
      end
    end
  end
end
