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
        
        [["REPLACE", {}, {}], ["REMOVE", {"COLLECTOR_LOG"=>0}, {}]].each do |second|
        
          it "should not spuriously require must_change params to be set on nodes when the must_change status of a param has changed since activation and the param set on the idgroup is #{second[0]}D (BZ654813)" do
            node = @store.addNode("barney")
            clog = @store.getParam("COLLECTOR_LOG")
            Group.DEFAULT_GROUP.modifyFeatures("ADD", %w{CentralManager Master NodeAccess}, {})
            Group.DEFAULT_GROUP.modifyParams("ADD", {"ALLOW_WRITE"=>"SURE", "ALLOW_READ"=>"WHYNOT", "CONDOR_HOST"=>"barney-laptop.local."}, {})
            @store.activateConfiguration.should == [{}, []]
            
            node.getConfig("version"=>node.last_updated_version)["COLLECTOR_LOG"].should_not == nil
            node.getConfig["COLLECTOR_LOG"].should_not == nil
            
            clog.setMustChange(true)

            # this is a hack to force reconfig to work
            Group.DEFAULT_GROUP.modifyParams("ADD", Group.DEFAULT_GROUP.params, {})

            @store.activateConfiguration.should == [{}, []]

            node.idgroup.modifyParams("ADD", {"COLLECTOR_LOG"=>"/tmp/CollectorLog"}, {})
            
            @store.activateConfiguration.should == [{}, []]
            
            node.idgroup.modifyParams(*second)
            
            @store.activateConfiguration.should == [{}, []]
          end
        end
      end
    end
  end
end
