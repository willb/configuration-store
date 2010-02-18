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
        
        it "should not be a member of any groups by default" do
          n = @store.AddNode("blather.local.")
          n.GetMemberships.size.should == 0
        end
        
        it "should be possible to add a node to a group" do
          n = @store.AddNode("blather.local.")
          groupnames = %w{ExecuteNodes HASchedulers DesktopMachines}
          groups = groupnames.map {|g| @store.AddExplicitGroup(g)}
          n.ModifyMemberships("ADD", FakeList[*groupnames])
          
          n.GetMemberships.size.should == groupnames.size
          n.GetMemberships.should == FakeList[*groupnames]
        end
        
        it "should not be possible to reproduce Rob's failure case" do
          node = @store.AddNode("guineapig.local.")
          group = @store.AddExplicitGroup("FAILNODES")
          
          # step 1:  add two mustchange params (and some other params for good measure)
          %w{FIRST SECOND THIRD FOURTH FIFTH}.each {|nm| @store.AddParam(nm).SetDefaultMustChange(true)}
          
          # step 2:  create a feature that has these params enabled
          feature = @store.AddFeature("Pony Accelerator")
          feature.ModifyParams("ADD", {"FIRST"=>0, "SECOND"=>0}, {})
          
          node.validate.should == true  # we haven't added this node to any groups yet
          
          # step 3:  add this feature to a group
          group.ModifyFeatures("ADD", FakeList[feature.name], {})
          
          node.validate.should == true  # we haven't added this node to any groups yet
          
          # step 4:  add this group to a node
          node.ModifyMemberships("ADD", FakeList[group.name], {})
          node.validate.should_not == true
          node.validate[1]["Unset necessary parameters"].should_not == nil
          node.validate[1]["Unset necessary parameters"].keys.size.should == 2
          node.validate[1]["Unset necessary parameters"].keys.should include("FIRST")
          node.validate[1]["Unset necessary parameters"].keys.should include("SECOND")
          
          # step 5:  add param one to the default group
          Group.DEFAULT_GROUP.ModifyParams("ADD", {"FIRST"=>"fooblitz"}, {})
          node.GetConfig["FIRST"].should == "fooblitz"
          node.validate.should_not == true
          node.validate[1]["Unset necessary parameters"].should_not == nil
          node.validate[1]["Unset necessary parameters"].keys.size.should == 1
          node.validate[1]["Unset necessary parameters"].keys.should_not include("FIRST")
          node.validate[1]["Unset necessary parameters"].keys.should include("SECOND")
          
          # step 6:  add param two to the group
          group.ModifyParams("ADD", {"SECOND"=>"blahrific"}, {})
          node.validate.should == true

          # step 7:  remove param two from the group
          group.ModifyParams("REMOVE", {"SECOND"=>"blahrific"}, {})
          node.validate.should_not == true
          node.validate[1]["Unset necessary parameters"].should_not == nil
          node.validate[1]["Unset necessary parameters"].keys.size.should == 1
          node.validate[1]["Unset necessary parameters"].keys.should_not include("FIRST")
          node.validate[1]["Unset necessary parameters"].keys.should include("SECOND")
          
          # step 8:  add param two to the group
          group.ModifyParams("ADD", {"SECOND"=>"blahrific"}, {})
          node.validate.should == true

          
        end

      end
      

    end
  end
end
