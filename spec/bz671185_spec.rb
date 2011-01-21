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
        
        it "should recognize that changes to features installed on the default group affect all nodes" do
          node = @store.addNode("foo")
          feature = @store.getFeature("Master")
          @store.addParam("BIOTECH")
          
          Group.DEFAULT_GROUP.modifyFeatures("ADD", %w{Master NodeAccess}, {})
          Group.DEFAULT_GROUP.modifyParams("ADD", {"CONDOR_HOST"=>"localhost", "ALLOW_WRITE"=>"localhost", "ALLOW_READ"=>"localhost"}, {})
          
          @store.activateConfiguration.should == [{}, []]
          
          feature.modifyParams("ADD", {"BIOTECH"=>"true"}, {})
          
          @store.activateConfiguration.should == [{}, []]
        end
      end
    end
  end
end