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

          @node = @store.getNode("example")
          @node.identity_group.modifyFeatures("REPLACE", ["CentralManager", "Scheduler"], {})
          @node.identity_group.modifyParams("REPLACE", {"ALLOW_NEGOTIATOR"=>"$(ALLOW_WRITE)", "ALLOW_NEGOTIATOR_SCHEDD"=>"$(ALLOW_WRITE)"}, {})
          @store.getDefaultGroup.modifyFeatures("REPLACE", ["Master", "NodeAccess", "SharedPort", "ExecuteNode"], {})
          @store.getDefaultGroup.modifyParams("REPLACE", {"SHARED_PORT_ARGS"=>"-p 9620", "UID_DOMAIN"=>"central-manager", "ALLOW_NEGOTIATOR"=>"$(ALLOW_WRITE)", "START"=>"TRUE", "ALLOW_READ"=>"*", "SUSPEND"=>"FALSE", "CONDOR_HOST"=>"1.2.3.4", "ALLOW_WRITE"=>"*", "ALLOW_NEGOTIATOR_SCHEDD"=>"$(ALLOW_WRITE)"}, {})
          @store.activateConfiguration
        end
        
        after(:each) do
          @node = nil
          teardown_rhubarb
        end
        
        include BaseDBFixture

        it "should preserve the default group configuration when appending from the identity group" do
          daemons = @node.getConfig("version"=>::Rhubarb::Util::timestamp)["DAEMON_LIST"].split(",").map {|s| s.strip}
          daemons.should include("MASTER")
          daemons.should include("STARTD")
          daemons.should include("SHARED_PORT")
          
          daemons.should include("SCHEDD")
          daemons.should include("NEGOTIATOR")
          daemons.should include("COLLECTOR")
        end

        it "should preserve the default group configuration when appending from the identity group even after eliminating spurious duplicated configs" do
          VersionedNodeConfig.delete_spurious

          daemons = @node.getConfig("version"=>::Rhubarb::Util::timestamp)["DAEMON_LIST"].split(",").map {|s| s.strip}
          daemons.should include("MASTER")
          daemons.should include("STARTD")
          daemons.should include("SHARED_PORT")
          
          daemons.should include("SCHEDD")
          daemons.should include("NEGOTIATOR")
          daemons.should include("COLLECTOR")
        end


        it "should only include the append markers once in group configs" do
          # XXX: fix this
          pending

          @node.identity_group.getConfig["DAEMON_LIST"].scan(/>=/).size.should == 1
          @store.getDefaultGroup.getConfig["DAEMON_LIST"].scan(/>=/).size.should == 1
        end
      end
    end
  end
end
