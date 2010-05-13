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
          config["BIOTECH"].should == "true"
          
          version = config_versions[0].version
          
          config = ConfigVersion.getVersionedNodeConfig("nodely.local.", version)
          config["BIOTECH"].should == "true"

          config = ConfigVersion.getVersionedNodeConfig("nodely.local.")
          config["BIOTECH"].should == "true"
        end
        
        it "should make two versioned configurations when activating an update to a node's configuration" do
          node = @store.addNode("nodely.local.")
          group = node.getIdentityGroup
          prm = @store.addParam("BIOTECH")
          prm = @store.addParam("PONY_COUNTER")

          group.modifyParams("ADD", {"BIOTECH"=>"true"})
          @store.activateConfiguration

          group.modifyParams("REPLACE", {"BIOTECH"=>"false", "PONY_COUNTER"=>"37"})
          @store.activateConfiguration
          
          config_versions = ConfigVersion.find_all
          config_versions.size.should == 2
          
          config = config_versions[0]["nodely.local."]
          config["BIOTECH"].should == "true"
          config["PONY_COUNTER"].should == nil
          
          config = config_versions[1]["nodely.local."]
          config["BIOTECH"].should == "false"
          config["PONY_COUNTER"].should == "37"
          
          version = config_versions[0].version
          version_prime = config_versions[1].version - 1
          
          config = ConfigVersion.getVersionedNodeConfig("nodely.local.", version)
          config["BIOTECH"].should == "true"
          config["PONY_COUNTER"].should == nil

          config = ConfigVersion.getVersionedNodeConfig("nodely.local.", version_prime)
          config["BIOTECH"].should == "true"
          config["PONY_COUNTER"].should == nil

          config = ConfigVersion.getVersionedNodeConfig("nodely.local.")
          config["BIOTECH"].should == "false"
          config["PONY_COUNTER"].should == "37"
        end

        it "should set the version of versioned configurations" do
          node = @store.addNode("nodely.local.")
          group = node.getIdentityGroup
          prm = @store.addParam("BIOTECH")
          prm = @store.addParam("PONY_COUNTER")

          group.modifyParams("ADD", {"BIOTECH"=>"true"})
          @store.activateConfiguration

          group.modifyParams("REPLACE", {"BIOTECH"=>"false", "PONY_COUNTER"=>"37"})
          @store.activateConfiguration
          
          config_versions = ConfigVersion.find_all
          config_versions.size.should == 2
          
          config = config_versions[0]["nodely.local."]
          config["BIOTECH"].should == "true"
          config["PONY_COUNTER"].should == nil
          
          config = config_versions[1]["nodely.local."]
          config["BIOTECH"].should == "false"
          config["PONY_COUNTER"].should == "37"
          
          early_version = config_versions[0].version
          late_version = config_versions[1].version
          
          config = ConfigVersion.getVersionedNodeConfig("nodely.local.", early_version)
          config["WALLABY_CONFIG_VERSION"].should == early_version.to_s

          config = ConfigVersion.getVersionedNodeConfig("nodely.local.", late_version)
          config["WALLABY_CONFIG_VERSION"].should == late_version.to_s

          config = ConfigVersion.getVersionedNodeConfig("nodely.local.", late_version - 1)
          config["WALLABY_CONFIG_VERSION"].should == early_version.to_s

          config = ConfigVersion.getVersionedNodeConfig("nodely.local.")
          config["WALLABY_CONFIG_VERSION"].should == late_version.to_s
        end

        
        it "should create a versioned configuration when activating a node's configuration when using Node#get_config" do
          node = @store.addNode("nodely.local.")
          group = node.getIdentityGroup
          prm = @store.addParam("BIOTECH")

          group.modifyParams("ADD", {"BIOTECH"=>"true"})

          @store.activateConfiguration

          config_versions = ConfigVersion.find_all
          config_versions.size.should == 1

          config = config_versions[0]["nodely.local."]
          config["BIOTECH"].should == "true"

          version = config_versions[0].version

          config = node.getConfig("version" => version)
          config["BIOTECH"].should == "true"

          config = node.getConfig()
          config["BIOTECH"].should == "true"
        end

        it "should make two versioned configurations when activating an update to a node's configuration when using Node#get_config" do
          node = @store.addNode("nodely.local.")
          group = node.getIdentityGroup
          prm = @store.addParam("BIOTECH")
          prm = @store.addParam("PONY_COUNTER")

          group.modifyParams("ADD", {"BIOTECH"=>"true"})
          @store.activateConfiguration

          group.modifyParams("REPLACE", {"BIOTECH"=>"false", "PONY_COUNTER"=>"37"})
          @store.activateConfiguration

          config_versions = ConfigVersion.find_all
          config_versions.size.should == 2

          config = config_versions[0]["nodely.local."]
          config["BIOTECH"].should == "true"
          config["PONY_COUNTER"].should == nil

          config = config_versions[1]["nodely.local."]
          config["BIOTECH"].should == "false"
          config["PONY_COUNTER"].should == "37"

          version = config_versions[0].version
          version_prime = config_versions[1].version - 1

          config = node.getConfig("version" => version)
          config["BIOTECH"].should == "true"
          config["PONY_COUNTER"].should == nil

          config = node.getConfig("version" => version_prime)
          config["BIOTECH"].should == "true"
          config["PONY_COUNTER"].should == nil

          config = node.getConfig()
          config["BIOTECH"].should == "false"
          config["PONY_COUNTER"].should == "37"
        end

        it "should set the version of versioned configurations when using Node#get_config" do
          node = @store.addNode("nodely.local.")
          group = node.getIdentityGroup
          prm = @store.addParam("BIOTECH")
          prm = @store.addParam("PONY_COUNTER")

          group.modifyParams("ADD", {"BIOTECH"=>"true"})
          @store.activateConfiguration

          group.modifyParams("REPLACE", {"BIOTECH"=>"false", "PONY_COUNTER"=>"37"})
          @store.activateConfiguration

          config_versions = ConfigVersion.find_all
          config_versions.size.should == 2

          config = config_versions[0]["nodely.local."]
          config["BIOTECH"].should == "true"
          config["PONY_COUNTER"].should == nil

          config = config_versions[1]["nodely.local."]
          config["BIOTECH"].should == "false"
          config["PONY_COUNTER"].should == "37"

          early_version = config_versions[0].version
          late_version = config_versions[1].version

          config = node.getConfig("version" => early_version)
          config["WALLABY_CONFIG_VERSION"].should == early_version.to_s

          config = node.getConfig("version" => late_version)
          config["WALLABY_CONFIG_VERSION"].should == late_version.to_s

          config = node.getConfig("version" => late_version - 1)
          config["WALLABY_CONFIG_VERSION"].should == early_version.to_s

          config = node.getConfig()
          config["WALLABY_CONFIG_VERSION"].should == late_version.to_s
        end


      end
    end
  end
end
