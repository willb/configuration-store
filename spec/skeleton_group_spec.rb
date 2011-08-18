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
        end

        it "should not place newly-provisioned nodes in the skeleton group" do
          n = @store.getNode("fake")
          n.modifyMemberships("REPLACE", [], {})
          n = @store.addNode("fake")
          n.memberships.should_not include(Group::SKELETON_GROUP_NAME)
        end
      end
    end
  end
end
