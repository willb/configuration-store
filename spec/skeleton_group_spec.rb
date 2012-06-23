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
            it "should give new #{kind} nodes the last-activated configuration for the skeleton group #{dowhen} and there is no default group" do
              @store.addParam("FOO")
              n_expected = @store.addNode("blah") if dowhen == "when another node exists at activation"
              g = @store.getGroupByName(Group::SKELETON_GROUP_NAME)
              g.modifyParams("REPLACE", {"FOO"=>"BAR"})
              @store.activateConfiguration
              g.modifyParams("REPLACE", {"FOO"=>"BLAH"})

              n = @store.send(msg, "fake")
              n.getConfig("version"=>::Rhubarb::Util::timestamp)["FOO"].should == "BAR"
            end

            it "should give new #{kind} nodes the last-activated configuration for the skeleton group #{dowhen} and there is a default group" do
              @store.addParam("FOO")
              @store.getDefaultGroup.modifyParams("REPLACE", {"FOO"=>"ARGH"}, {})
              @store.activateConfiguration
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
        
        it "should not exhibit Matt's failure case with walkin nodes not getting the skeleton group config" do
          default = @store.getDefaultGroup
          skel = @store.getSkeletonGroup
          
          # wallaby add-features-to-group +++DEFAULT Master NodeAccess SharedPort
          default.modifyFeatures("ADD", %w{Master NodeAccess SharedPort}, {})
          
          # wallaby add-params-to-group +++DEFAULT 'SHARED_PORT_ARGS=-p 9620' 'CONDOR_HOST=$(QMF_BROKER_HOST)' 'ALLOW_WRITE=*' 'ALLOW_READ=*' 'ALLOW_NEGOTIATOR=$(ALLOW_WRITE)' 'ALLOW_NEGOTIATOR_SCHEDD=$(ALLOW_WRITE)' UID_DOMAIN=central-manager
          default.modifyParams("ADD", {'SHARED_PORT_ARGS'=>'-p 9620', 'CONDOR_HOST'=>'$(QMF_BROKER_HOST)', 'ALLOW_WRITE'=>'*', 'ALLOW_READ'=>'*', 'ALLOW_NEGOTIATOR'=>'$(ALLOW_WRITE)', 'ALLOW_NEGOTIATOR_SCHEDD'=>'$(ALLOW_WRITE)', 'UID_DOMAIN'=>'central-manager'}, {})
          
          # wallaby add-features-to-group +++SKEL ExecuteNode
          skel.modifyFeatures("ADD", %w{ExecuteNode}, {})
          
          # wallaby add-params-to-group +++SKEL START=TRUE SUSPEND=FALSE
          skel.modifyParams("ADD", {'START'=>'TRUE', 'SUSPEND'=>'FALSE'}, {})
          
          # wallaby add-node central-manager
          cm = @store.addNode('central-manager')
          
          # wallaby add-param COLLECTOR_UPDATE_INTERVAL (needs to go to base DB)
          @store.addParam('COLLECTOR_UPDATE_INTERVAL')
          
          # wallaby remove-nodes-from-group +++SKEL central-manager
          cm.modifyMemberships("REPLACE", cm.memberships - %w{+++SKEL}, {})
          
          # wallaby add-features-to-node central-manager CentralManager Scheduler (maybe: JobServer)
          cm.identity_group.modifyFeatures("ADD", %w{CentralManager Scheduler JobServer}, {})
          
          # wallaby add-params-to-node central-manager COLLECTOR_UPDATE_INTERVAL=15
          cm.identity_group.modifyParams("ADD", {"COLLECTOR_UPDATE_INTERVAL"=>15})
          
          # wallaby activate
          @store.activateConfiguration.should == [{}, []]
          
          # newly checked-in nodes should get skeleton group configuration
          wi = @store.getNode("walk-in")
          wi_config = wi.getConfig("version"=>::Rhubarb::Util::timestamp)
          daemons = wi_config["DAEMON_LIST"].split(",").map {|s| s.strip}
          daemons.should include("STARTD")
          wi_config["START"].should == "TRUE"
          wi_config["SUSPEND"].should == "FALSE"
        end

        it "should publish the skeleton group over the API" do
          @store.getSkeletonGroup.name.should == Group::SKELETON_GROUP_NAME
        end
      end
    end
  end
end

