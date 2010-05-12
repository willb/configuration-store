require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module Mrg
  module Grid
    module Config
      describe ConfigVersion do
        before(:each) do
          setup_rhubarb
          @store = Store.new
        end
        
        after(:each) do
          teardown_rhubarb
        end

        it "should create a versioned configuration when activating a node's configuration" do
          node = @store.addNode("nodely.local.")
          group = node.getIdentityGroup
          prm = @store.addParam("BIOTECH")

          group.modifyParams("ADD", {"BIOTECH"=>"true"})

          @store.activateConfiguration
          
          config_versions = ConfigVersion.find_all
          config_versions.size.should == 1
          
          config = config_versions[0]["nodely.local."]
          puts config.inspect
          config["BIOTECH"].should == "true"          
          
          config = ConfigVersion.getVersionedNodeConfig("nodely.local.")
          puts config.inspect
          config["BIOTECH"].should == "true"
        end
      end
    end
  end
end
