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
        
        it "should be unprovisioned unless explicitly added" do
          n = @store.GetNode("thather.local.")
          n.provisioned.should_not == true
        end

        it "should be provisioned if explicitly added" do
          n = @store.AddNode("thather.local.")
          n.provisioned.should == true
        end

        it "should have no last check-in time by default when unprovisioned" do
          n = @store.GetNode("thather.local.")
          n.last_checkin.should == 0
        end

        it "should have no last check-in time by default when provisioned" do
          n = @store.AddNode("thather.local.")
          n.last_checkin.should == 0
        end

        it "should have a nonzero last check-in time after checkin" do
          n = @store.AddNode("thather.local.")
          n.checkin
          n.last_checkin.should > 0
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
      
        {"provisioned"=>:AddNode, "unprovisioned"=>:GetNode}.each do |nodekind, node_find_msg|
          [["an explicit group", Proc.new {|store| store.AddExplicitGroup("SETNODES")}, Proc.new {|node, group| node.ModifyMemberships("ADD", FakeList[group.name], {})}], ["the default group", Proc.new {|store| Group.DEFAULT_GROUP}, Proc.new {|node, group| nil }]].each do |from, group_locator, modify_memberships|

            it "should, if it is #{nodekind}, include StringSet parameter values from #{from}" do
              node = @store.send(node_find_msg, "guineapig.local.")
              group = group_locator.call(@store)

              param = @store.AddParam("STRINGSET")

              group.ModifyParams("ADD", {"STRINGSET" => ">= FOO"}, {})

              modify_memberships.call(node, group)
              config = node.GetConfig

              config.should have_key("STRINGSET")
              config["STRINGSET"].should match(/FOO/)
            end

            it "should, if it is #{nodekind}, not include commas after single StringSet parameter values from #{from}" do
              node = @store.send(node_find_msg, "guineapig.local.")
              group = group_locator.call(@store)

              param = @store.AddParam("STRINGSET")

              group.ModifyParams("ADD", {"STRINGSET" => ">= FOO"}, {})

              modify_memberships.call(node, group)
              config = node.GetConfig

              config.should have_key("STRINGSET")
              config["STRINGSET"].should_not match(/,/)
            end

            it "should, if it is #{nodekind}, not include whitespace after single StringSet parameter values from #{from}" do
              node = @store.send(node_find_msg, "guineapig.local.")
              group = group_locator.call(@store)

              param = @store.AddParam("STRINGSET")

              group.ModifyParams("ADD", {"STRINGSET" => ">= FOO"}, {})

              modify_memberships.call(node, group)
              config = node.GetConfig

              config.should have_key("STRINGSET")
              config["STRINGSET"].should match(/FOO$/)
            end

            it "should, if it is #{nodekind}, not include StringSet append indicators in parameter values from #{from}" do
              node = @store.send(node_find_msg, "guineapig.local.")
              group = group_locator.call(@store)

              param = @store.AddParam("STRINGSET")

              group.ModifyParams("ADD", {"STRINGSET" => ">= FOO"}, {})

              modify_memberships.call(node, group)
              config = node.GetConfig

              config.should have_key("STRINGSET")
              config["STRINGSET"].should_not match(/^>=/)
            end
          end

          it "should, if it is #{nodekind}, properly append StringSet values to features added from the default group and parameters from the identity group" do
            node = @store.send(node_find_msg, "guineapig.local.")
            feature1 = @store.AddFeature("FOOFEATURE")
            feature2 = @store.AddFeature("BARFEATURE")

            param = @store.AddParam("STRINGSET")

            feature1.ModifyParams("ADD", {"STRINGSET" => ">= FOO"}, {})
            feature2.ModifyParams("ADD", {"STRINGSET" => ">= BAR"}, {})

            Group.DEFAULT_GROUP.ModifyFeatures("ADD", FakeList[feature2.name, feature1.name], {})
            node.GetIdentityGroup.ModifyParams("ADD", {"STRINGSET"=>">= BLAH"}, {})
            config = node.GetConfig

            config.should have_key("STRINGSET")
            stringset_values = config["STRINGSET"].split(/, |,| /)
            stringset_values.size.should == 3
            %w{FOO BAR BLAH}.each {|val| stringset_values.should include(val)}
            %w{FOO BAR BLAH}.each_with_index {|val,i| stringset_values[i].should == val}         
          end

          it "should, if it is #{nodekind}, properly append StringSet values to features added from the default group and features from the identity group" do
            node = @store.send(node_find_msg, "guineapig.local.")
            feature1 = @store.AddFeature("FOOFEATURE")
            feature2 = @store.AddFeature("BARFEATURE")
            feature3 = @store.AddFeature("BLAHFEATURE")

            param = @store.AddParam("STRINGSET")

            feature1.ModifyParams("ADD", {"STRINGSET" => ">= FOO"}, {})
            feature2.ModifyParams("ADD", {"STRINGSET" => ">= BAR"}, {})
            feature3.ModifyParams("ADD", {"STRINGSET" => ">= BLAH"}, {})

            Group.DEFAULT_GROUP.ModifyFeatures("ADD", FakeList[feature2.name, feature1.name], {})
            node.GetIdentityGroup.ModifyFeatures("ADD", FakeList[feature3.name], {})
            config = node.GetConfig

            config.should have_key("STRINGSET")
            stringset_values = config["STRINGSET"].split(/, |,| /)

            stringset_values.size.should == 3
            %w{FOO BAR BLAH}.each {|val| stringset_values.should include(val)}
            %w{FOO BAR BLAH}.each_with_index {|val,i| stringset_values[i].should == val}         
          end

          it "should, if it is #{nodekind}, properly append all StringSet parameter values from a default group and an explicit group" do
            node = @store.send(node_find_msg, "guineapig.local.")
            group = @store.AddExplicitGroup("SETNODES")

            param = @store.AddParam("STRINGSET")

            Group.DEFAULT_GROUP.ModifyParams("ADD", {"STRINGSET" => ">= FOO"}, {})
            group.ModifyParams("ADD", {"STRINGSET" => ">= BAR"}, {})

            node.ModifyMemberships("ADD", FakeList[group.name], {})
            config = node.GetConfig

            config.should have_key("STRINGSET")
            stringset_values = config["STRINGSET"].split(/, |,| /)

            stringset_values.size.should == 2
            %w{FOO BAR}.each {|val| stringset_values.should include(val)}
            %w{FOO BAR}.each_with_index {|val,i| stringset_values[i].should == val}
          end

          it "should, if it is #{nodekind}, properly append all StringSet parameter values from two features" do
            node = @store.send(node_find_msg, "guineapig.local.")
            feature1 = @store.AddFeature("FOOFEATURE")
            feature2 = @store.AddFeature("BARFEATURE")

            param = @store.AddParam("STRINGSET")

            feature1.ModifyParams("ADD", {"STRINGSET" => ">= FOO"}, {})
            feature2.ModifyParams("ADD", {"STRINGSET" => ">= BAR"}, {})

            node.GetIdentityGroup.ModifyFeatures("ADD", FakeList[feature2.name, feature1.name], {})
            config = node.GetConfig

            config.should have_key("STRINGSET")
            stringset_values = config["STRINGSET"].split(/, |,| /)
            stringset_values.size.should == 2
            %w{FOO BAR}.each {|val| stringset_values.should include(val)}
            %w{FOO BAR}.each_with_index {|val,i| stringset_values[i].should == val}
          end


          it "should, if it is #{nodekind}, properly append all StringSet parameter values from two explicit groups" do
            node = @store.send(node_find_msg, "guineapig.local.")
            group2 = @store.AddExplicitGroup("FOONODES")
            group1 = @store.AddExplicitGroup("BARNODES")

            param = @store.AddParam("STRINGSET")

            group1.ModifyParams("ADD", {"STRINGSET" => ">= FOO"}, {})
            group2.ModifyParams("ADD", {"STRINGSET" => ">= BAR"}, {})

            node.ModifyMemberships("ADD", FakeList[group2.name, group1.name], {})
            config = node.GetConfig

            config.should have_key("STRINGSET")
            stringset_values = config["STRINGSET"].split(/, |,| /)
            stringset_values.size.should == 2
            %w{FOO BAR}.each {|val| stringset_values.should include(val)}
            %w{FOO BAR}.each_with_index {|val,i| stringset_values[i].should == val}
          end

          it "should, if it is #{nodekind}, not validate configurations that do not provide features depended upon by enabled features (in the default group)" do
            features = %w{FooFeature BarFeature}.map {|fname| @store.AddFeature(fname)}
            features[0].ModifyDepends("ADD", FakeList[features[1].name], {})

            Group.DEFAULT_GROUP.ModifyFeatures("ADD", FakeList[features[0].name], {})

            node = @store.send(node_find_msg, "blah.local.")
            config = node.GetConfig
            node.validate.should_not == true
            node.validate[1][Node::BROKEN_FEATURE_DEPS].keys.should include("BarFeature")

            explain = @store.ActivateConfiguration
            explain.should_not == {}
            explain["blah.local."][Node::BROKEN_FEATURE_DEPS].keys.should include("BarFeature")
          end

          it "should, if it is #{nodekind}, not validate configurations that do not provide features depended upon by enabled features (in the idgroup)" do
            features = %w{FooFeature BarFeature}.map {|fname| @store.AddFeature(fname)}
            features[0].ModifyDepends("ADD", FakeList[features[1].name], {})

            node = @store.send(node_find_msg, "blah.local.")

            node.GetIdentityGroup.ModifyFeatures("ADD", FakeList[features[0].name], {})

            config = node.GetConfig
            node.validate.should_not == true
            node.validate[1][Node::BROKEN_FEATURE_DEPS].keys.should include("BarFeature")
          end

          it "should, if it is #{nodekind}, not validate configurations that do not provide values for must-change parameters" do
            param = @store.AddParam("FOO")
            param.SetDefaultMustChange(true)

            feature = @store.AddFeature("FooFeature")
            feature.ModifyParams("ADD", {"FOO"=>0}, {})

            node = @store.send(node_find_msg, "blah.local.")
            node.GetIdentityGroup.ModifyFeatures("ADD", FakeList[feature.name], {})

            config = node.GetConfig

            node.validate.should_not == true
            node.validate[1][Node::UNSET_MUSTCHANGE_PARAMS].keys.should include("FOO")
          end

          [true, false].each do |mustchange|

            mustchangestr = mustchange ? "must-change" : "defaultable"

            it "should, if it is #{nodekind}, validate configurations that provide values for #{mustchangestr} parameters at a lower priority than the bare inclusion" do
              param = @store.AddParam("FOO")
              param.SetDefaultMustChange(mustchange)

              feature = @store.AddFeature("FooFeature")
              feature.ModifyParams("ADD", {"FOO"=>0}, {})

              node = @store.send(node_find_msg, "blah.local.")
              node.GetIdentityGroup.ModifyFeatures("ADD", FakeList[feature.name], {})

              Group.DEFAULT_GROUP.ModifyParams("ADD", {"FOO"=>"ARGH"}, {})

              config = node.GetConfig

              node.validate.should == true
              config["FOO"].should == "ARGH"
            end

            it "should, if it is #{nodekind}, validate configurations that provide values for #{mustchangestr} parameters at a higher priority than the bare inclusion" do
              param = @store.AddParam("FOO")
              param.SetDefaultMustChange(mustchange)

              feature = @store.AddFeature("FooFeature")
              feature.ModifyParams("ADD", {"FOO"=>0}, {})

              node = @store.send(node_find_msg, "blah.local.")
              Group.DEFAULT_GROUP.ModifyFeatures("ADD", FakeList[feature.name], {})

              node.GetIdentityGroup.ModifyParams("ADD", {"FOO"=>"ARGH"}, {})

              config = node.GetConfig

              node.validate.should == true
              config["FOO"].should == "ARGH"
            end

            it "should, if it is #{nodekind}, validate configurations that provide values for #{mustchangestr} parameters to a feature at a higher priority than the bare inclusion" do
              param = @store.AddParam("FOO")
              param.SetDefaultMustChange(mustchange)

              feature = @store.AddFeature("FooFeature")
              feature.ModifyParams("ADD", {"FOO"=>0}, {})

              feature2 = @store.AddFeature("LocalFooFeature")
              feature2.ModifyParams("ADD", {"FOO"=>"BLAH"}, {})


              node = @store.send(node_find_msg, "blah.local.")
              Group.DEFAULT_GROUP.ModifyFeatures("ADD", FakeList[feature.name], {})

              node.GetIdentityGroup.ModifyFeatures("ADD", FakeList[feature2.name], {})

              config = node.GetConfig

              node.validate.should == true
              config["FOO"].should == "BLAH"
            end

            it "should, if it is #{nodekind}, validate configurations that provide values for multiple #{mustchangestr} parameters to an identity group at a higher priority than the bare inclusion" do
              params = %w{FOO BAR BLAH}.map {|pname| @store.AddParam(pname)}
              params.each {|param| param.SetDefaultMustChange(mustchange)}

              features = %w{FooBarFeature BlahFeature}.map {|fname| @store.AddFeature(fname)}
              features[0].ModifyParams("ADD", {"FOO"=>0, "BAR"=>0}, {})
              features[1].ModifyParams("ADD", {"BLAH"=>0}, {})

              node = @store.send(node_find_msg, "blah.local.")
              Group.DEFAULT_GROUP.ModifyFeatures("ADD", FakeList[features.map{|f| f.name}], {})

              node.GetIdentityGroup.ModifyParams("ADD", {"FOO"=>"ARGH", "BAR"=>"BARGH", "BLAH"=>"BLARGH"}, {})

              config = node.GetConfig

              node.validate.should == true
              config["FOO"].should == "ARGH"
              config["BAR"].should == "BARGH"
              config["BLAH"].should == "BLARGH"
            end

            it "should, if it is #{nodekind}, validate configurations that provide values for multiple #{mustchangestr} parameters to a group at a lower priority than the bare inclusion" do
              params = %w{FOO BAR BLAH}.map {|pname| @store.AddParam(pname)}
              params.each {|param| param.SetDefaultMustChange(mustchange)}

              features = %w{FooBarFeature BlahFeature}.map {|fname| @store.AddFeature(fname)}
              features[0].ModifyParams("ADD", {"FOO"=>0, "BAR"=>0}, {})
              features[1].ModifyParams("ADD", {"BLAH"=>0}, {})

              node = @store.send(node_find_msg, "blah.local.")
              node.GetIdentityGroup.ModifyFeatures("ADD", FakeList[features.map{|f| f.name}], {})

              Group.DEFAULT_GROUP.ModifyParams("ADD", {"FOO"=>"ARGH", "BAR"=>"BARGH", "BLAH"=>"BLARGH"}, {})

              config = node.GetConfig

              node.validate.should == true
              config["FOO"].should == "ARGH"
              config["BAR"].should == "BARGH"
              config["BLAH"].should == "BLARGH"
            end

            it "should, if it is #{nodekind}, validate configurations that provide values for multiple #{mustchangestr} parameters both to a group at a lower priority than and to a group at the same priority as the bare inclusion" do
              params = %w{FOO BAR BLAH}.map {|pname| @store.AddParam(pname)}
              params.each {|param| param.SetDefaultMustChange(mustchange)}

              features = %w{FooBarFeature BlahFeature}.map {|fname| @store.AddFeature(fname)}
              features[0].ModifyParams("ADD", {"FOO"=>0, "BAR"=>0}, {})
              features[1].ModifyParams("ADD", {"BLAH"=>0}, {})

              node = @store.send(node_find_msg, "blah.local.")
              node.GetIdentityGroup.ModifyFeatures("ADD", FakeList[features.map{|f| f.name}], {})

              Group.DEFAULT_GROUP.ModifyParams("ADD", {"FOO"=>"ARGH", "BLAH"=>"BLARGH"}, {})
              node.GetIdentityGroup.ModifyParams("ADD", {"BAR"=>"BARGH"}, {})

              config = node.GetConfig

              node.validate.should == true
              config["FOO"].should == "ARGH"
              config["BAR"].should == "BARGH"
              config["BLAH"].should == "BLARGH"
            end

            it "should, if it is #{nodekind}, report the highest-priority parameter value in configurations that provide values for #{mustchangestr} parameters in multiple places" do
              params = %w{FOO BAR BLAH}.map {|pname| @store.AddParam(pname)}
              params.each {|param| param.SetDefaultMustChange(mustchange)}

              features = %w{FooBarFeature BlahFeature}.map {|fname| @store.AddFeature(fname)}
              features[0].ModifyParams("ADD", {"FOO"=>0, "BAR"=>0}, {})
              features[1].ModifyParams("ADD", {"BLAH"=>0}, {})

              node = @store.send(node_find_msg, "blah.local.")
              node.GetIdentityGroup.ModifyFeatures("ADD", FakeList[features.map{|f| f.name}], {})

              Group.DEFAULT_GROUP.ModifyParams("ADD", {"FOO"=>"ARGH", "BLAH"=>"BLARGH"}, {})
              node.GetIdentityGroup.ModifyParams("ADD", {"BAR"=>"BARGH", "BLAH"=>"blargh"}, {})

              config = node.GetConfig

              node.validate.should == true
              config["FOO"].should == "ARGH"
              config["BAR"].should == "BARGH"
              config["BLAH"].should == "blargh"
            end
          end
        end

        it "should have only one identity group" do
          pending
        end
      end
    end
  end
end
