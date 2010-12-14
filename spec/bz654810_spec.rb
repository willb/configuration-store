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
        def check_config_changes(node, param, version_ls)
          old_v, new_v = version_ls[-2], version_ls[-1]
          if node.getConfig("version"=>old_v)[param] != node.getConfig("version"=>new_v)[param]
            params, restart, reconfig = node.whatChanged(old_v, new_v)
            params.should include(param)
            
            ss = Subsystem.s_for_param(param).map {|s| s.name}
            (restart | reconfig).should include(*ss)
          end
        end
        
        include BaseDBFixture
        
        
        ["/tmp/CollectorLog", "/tmp/BogusLog"].each do |target|
          [["REPLACE", {}, {}], ["REMOVE", {"COLLECTOR_LOG"=>0}, {}]].each do |second|
          
            it "should correctly signal parameter reconfigs when the must_change status of a param has changed since activation and the param set on the idgroup is #{second[0]}D (BZ654810)" do
              node = @store.addNode("barney")
              node_versions = [0]
              
              clog = @store.getParam("COLLECTOR_LOG")
              
              clog.permissive = true
              
              Group.DEFAULT_GROUP.modifyFeatures("ADD", %w{CentralManager Master NodeAccess}, {})
              Group.DEFAULT_GROUP.modifyParams("ADD", {"ALLOW_WRITE"=>"SURE", "ALLOW_READ"=>"WHYNOT", "CONDOR_HOST"=>"barney-laptop.local."}, {})
              @store.activateConfiguration.should == [{}, []]
              node_versions << node.last_updated_version
              
              node.getConfig("version"=>node.last_updated_version)["COLLECTOR_LOG"].should_not == nil
              node.getConfig["COLLECTOR_LOG"].should_not == nil
              
              clog.setMustChange(true)
  
              # this is a hack to force reconfig to work
              Group.DEFAULT_GROUP.modifyParams("ADD", Group.DEFAULT_GROUP.params, {})
  
              @store.activateConfiguration.should == [{}, []]
              node_versions << node.last_updated_version
              check_config_changes(node, "COLLECTOR_LOG", node_versions)
              
              node.idgroup.modifyParams("ADD", {"COLLECTOR_LOG"=>target}, {})
              
              @store.activateConfiguration.should == [{}, []]
              node_versions << node.last_updated_version
              check_config_changes(node, "COLLECTOR_LOG", node_versions)
              
              node.idgroup.modifyParams(*second)
              
              @store.activateConfiguration.should == [{}, []]
              node_versions << node.last_updated_version
              check_config_changes(node, "COLLECTOR_LOG", node_versions)
              
            end
          end
        end
      end
    end
  end
end
