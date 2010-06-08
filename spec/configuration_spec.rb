require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module Mrg
  module Grid
    module Config
      describe ConfigUtils do
        def setup_increasing_hash(keys, startval=0)
          Hash[*keys.zip((startval...(startval+keys.size)).to_a).flatten]
        end
        
        before(:each) do
          @h1keys = %w{foo bar blah argh}
          @h2keys = %w{bar blah argh crumb}
          @h3keys = %w{ugh foo bar blah argh}
          
          @h1 = setup_increasing_hash(@h1keys, 0)
          @h2 = setup_increasing_hash(@h2keys, 0)
          @h2_5 = setup_increasing_hash(@h2keys, 1)
          @h3 = setup_increasing_hash(@h3keys, 0)
          @h1_3 = setup_increasing_hash(@h1keys, 1)
        end

        it "should identify that the symmetric difference of a hash with itself is empty" do
          ConfigUtils.diff(@h1, @h1).should == []
        end

        it "should identify that the symmetric difference of a hash with an identical hash is empty" do
          ConfigUtils.diff(@h1, @h1.dup).should == []
        end

        {:first=>"", :second=>", symmetrically"}.each do |ordering, qualifier|
        
          it "should correctly find the symmetric difference of two hashes with nothing in common#{qualifier}" do
            thediff = ordering == :first ? ConfigUtils.diff(@h1, @h2) : ConfigUtils.diff(@h2, @h1)
          
            thediff.size.should == @h1keys.size + @h2keys.size 

            [@h1,@h2].each do |coll|
              coll.each do |pair|
                thediff.should include(pair)
              end
            end
          
          end
          
          it "should correctly find the symmetric difference of two hashes with most of the kv-pairs in common when the differing keys are disjoint#{qualifier}" do
            thediff = ordering == :first ? ConfigUtils.diff(@h1, @h2_5) : ConfigUtils.diff(@h2_5, @h1)
            
            keydiff = ((@h1keys | @h2keys) - (@h1keys & @h2keys))
            
            thediff.size.should == keydiff.size

            {@h1=>@h1keys-@h2keys, @h2_5=>@h2keys-@h1keys}.each do |from, whichs|
              whichs.each do |which|
                thediff.should include([which, from[which]])
              end
            end
          end
          
        end
        
      end

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
          group = node.identity_group
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
          group = node.identity_group
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
          group = node.identity_group
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
          group = node.identity_group
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
          group = node.identity_group
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
          group = node.identity_group
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
