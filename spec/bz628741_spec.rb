# - !ruby/object:Mrg::Grid::SerializedConfigs::Parameter 
#   conflicts: []
# 
#   default_val: ( ((Activity == "Suspended") && ($(ActivityTimer) > $(MaxSuspendTime))) || (SUSPEND && (WANT_SUSPEND == False)) )
#   depends: []
# 
#   description: Describes when a machine will nicely stop a job
#   kind: String
#   level: 0
#   must_change: false
#   name: PREEMPT
#   needs_restart: false
#   
# - !ruby/object:Mrg::Grid::SerializedConfigs::Feature 
#   conflicts: []
# 
#   depends: []
# 
#   included: []
# 
#   name: DisablePreemption
#   params: 
#     RANK: "0"
#     NEGOTIATOR_CONSIDER_PREEMPTION: "FALSE"
#     PREEMPTION_REQUIREMENTS: "FALSE"
#     PREEMPT: "FALSE"

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
          
          @preempt = @store.getParam("PREEMPT")
          @bogus_feature = @store.addFeature("Bogus")
          @bogus_feature.modifyParams("ADD", {"PREEMPT"=>0}, {})
          
          @disable_preemption = @store.addFeature("DisablePreemption")
          @disable_preemption.modifyParams("ADD", {"RANK"=>"0", "PREEMPTION_REQUIREMENTS"=>"FALSE", "PREEMPT"=>"FALSE"}, {})
          @node = @store.addNode("eeny")
        end
        
        after(:each) do
          teardown_rhubarb
        end
        
        include BaseDBFixture
        
        # it "should have a better example name than this!"
        it "should not revert to default values for parameters whose given value is 'FALSE'" do
          @node.idgroup.modifyFeatures("ADD", ["DisablePreemption"])
          
          config = @node.getConfig
          
          config["PREEMPT"].should_not == @preempt.default_val
          config["PREEMPT"].upcase.should == "FALSE"
        end
      end
    end
  end
end