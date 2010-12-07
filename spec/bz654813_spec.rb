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
        
        it "should not spuriously require must_change params to be set on nodes when the must_change status of a param has changed since activation (BZ654813)" do
          node = @store.addNode("barney")
          clog = @store.getParam("COLLECTOR_LOG")
          Group.DEFAULT_GROUP.modifyFeatures("ADD", %w{CentralManager Master NodeAccess}, {})
          Group.DEFAULT_GROUP.modifyParams("ADD", {"ALLOW_WRITE"=>"SURE", "ALLOW_READ"=>"WHYNOT", "CONDOR_HOST"=>"barney-laptop.local."}, {})
          @store.activateConfiguration.should == [{}, []]
          
          node.getConfig("version"=>node.last_updated_version)["COLLECTOR_LOG"].should_not == nil
          node.getConfig["COLLECTOR_LOG"].should_not == nil
          
          node.idgroup.modifyParams("ADD", {"COLLECTOR_LOG"=>"/tmp/CollectorLog"}, {})
          
          @store.activateConfiguration.should == [{}, []]

          node.idgroup.modifyParams("REPLACE", {}, {})
          
          @store.activateConfiguration.should == [{}, []]
          
        end
      end
    end
  end
end