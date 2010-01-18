require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'digest/md5'

module Mrg
  module Grid
    module Config

      describe Node do
        before(:each) do
          setup_rhubarb
          @store = Store.new
        end
        
        after(:each) do
          teardown_rhubarb
        end
        
        it "should be possible to create a node with a given name" do
          n = @store.AddNode("blather.local.")
          n.name.should == "blather.local."
        end

        it "should be possible to create a node and then retrieve it" do
          n1 = @store.AddNode("blather.local.")
          n2 = @store.GetNode("blather.local.")
          n1.name.should == n2.name
          n1.row_id.should == n2.row_id
        end

        it "should update the node name when the name is set" do
          n = @store.AddNode("blather.local.")

          bogus_name = ""
          9.times { bogus_name << ((rand*26).floor + ?a).chr }

          rid = n.row_id
          n.name = bogus_name
          n.name.should == bogus_name

          n = @store.GetNode(bogus_name)
          n.name.should == bogus_name
          n.row_id.should == rid
        end

        it "should have a way to access the pool value" do
          n = @store.AddNode("blather.local.")
          n.should respond_to(:GetPool)
        end

        it "should have a way to modify the pool value" do
          n = @store.AddNode("blather.local.")
          n.should respond_to(:SetPool)
        end

        it "should have an affiliated identity group" do
          n = @store.AddNode("blather.local.")
          group = n.GetIdentityGroup
          
          expected_group_name = "+++#{Digest::MD5.hexdigest("blather.local.")}"
          group.should_not == nil
          group.name.should == expected_group_name
        end

        ["add","ADD"].each do |p_cmd|
          it "should be possible to #{p_cmd} params on the identity group" do
            n = @store.AddNode("blather.local.")
            group = n.GetIdentityGroup
            prm = @store.AddParam("BIOTECH")

            group.ModifyParams(p_cmd, {"BIOTECH"=>"true"})

            conf = n.GetConfig

            conf.keys.should include("BIOTECH")
            conf["BIOTECH"].should == "true"
          end

          it "should be possible to #{p_cmd} features on the identity group" do
            n = @store.AddNode("blather.local.")
            group = n.GetIdentityGroup
            
            @store.AddParam("BIOTECH")
            @store.AddParam("UKULELE")
            
            f1 = @store.AddFeature("BLAH1")
            f2 = @store.AddFeature("BLAH2")
  
            f1.ModifyParams(p_cmd, {"BIOTECH"=>"ichi"})
            f1.ModifyParams(p_cmd, {"UKULELE"=>"gcae"})
            group.ModifyFeatures(p_cmd, FakeList["BLAH1"])
  
            conf = n.GetConfig
            conf.keys.should include("BIOTECH")
            conf["BIOTECH"].should == "ichi"
            conf["UKULELE"].should == "gcae"
  
            f2.ModifyParams(p_cmd, {"BIOTECH"=>"ni"})
            group.ModifyFeatures("REPLACE", FakeList["BLAH2", "BLAH1"])
  
            conf = n.GetConfig
            conf.keys.should include("BIOTECH")
            conf["BIOTECH"].should == "ni"
            conf["UKULELE"].should == "gcae"
            
            group.ModifyParams(p_cmd, {"BIOTECH"=>"san"})
  
            conf = n.GetConfig
            conf.keys.should include("BIOTECH")
            conf["BIOTECH"].should == "san"
            conf["UKULELE"].should == "gcae"
          end
        end

      end
      

    end
  end
end
