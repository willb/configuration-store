require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module Mrg
  module Grid
    module Config
      describe Feature do
        
        before(:each) do
          setup_rhubarb
          @store = Store.new
          @add_msg = :addFeature
          @find_msg = :getFeature
          @gskey = "MORE_PONIES"
        end

        after(:each) do
          teardown_rhubarb
        end

        include DescribeGetterAndSetter
        
        it "should be instantiable" do
          feature = @store.addFeature(@gskey)
          @store.getFeature(@gskey).row_id.should == feature.row_id
        end

        it "should not persist after deletion" do
          feature = @store.addFeature(@gskey)
          @store.removeFeature(@gskey)
          lambda {@store.getFeature(@gskey)}.should raise_error
          lambda {@store.removeFeature(@gskey)}.should raise_error
        end
        
        it "should allow setting a feature's name" do
          vals = ["Fewer ponies", "Some ponies", "No ponies"]
          feature = @store.addFeature(@gskey)

          vals.each do |val|
            old_rid = feature.row_id
            feature.setName(val)
            
            feature = @store.getFeature(val)
            feature.row_id.should == old_rid
          end
        end
        
        it "should not allow creating a feature with a taken name" do
          feature = @store.addFeature(@gskey)
          lambda { feature2 = @store.addFeature(@gskey) }.should raise_error
          
        end
        
        it "should not allow setting a feature's name to a taken name" do
          feature = @store.addFeature(@gskey)
          feature2 = @store.addFeature("Fewer ponies")
          
          lambda { feature2.setName(@gskey) }.should raise_error
        end
        
        it "should allow adding parameter/value mappings one at a time" do
          param_names = ("XAA".."XAZ").to_a
          param_values = param_names.map {|pn| pn.downcase}
          params = param_names.map {|pn| @store.addParam(pn)}
          feature = @store.addFeature(@gskey)
          old_size = 0
          
          param_names.zip(param_values).each do |k,v|
            feature.modifyParams("ADD", {k=>v})
            mappings = feature.params
            mappings.size.should == old_size + 1
            mappings.keys.should include(k)
            mappings[k].should == v
            
            old_size = mappings.size
          end
        end

        it "should allow adding parameter/value mappings all at once" do
          param_names = ("XAA".."XAZ").to_a
          param_values = param_names.map {|pn| pn.downcase}
          
          pvmap = Hash[*param_names.zip(param_values).flatten]

          params = param_names.map {|pn| @store.addParam(pn)}

          feature = @store.addFeature(@gskey)
          feature.modifyParams("ADD", pvmap)
          
          mappings = feature.params
          
          mappings.size.should == pvmap.size
          
          param_names.zip(param_values).each do |k,v|
            mappings.keys.should include(k)
            mappings[k].should == v
          end
        end

        it "should allow replacing parameter/value mappings" do
          param_names = ("XAA".."XAZ").to_a
          param_values = param_names.map {|pn| pn.downcase}
          
          nvps = *param_names.zip(param_values)
          
          pvmap1 = Hash[*nvps.slice(0,5).flatten]
          pvmap2 = Hash[*nvps.slice(5,nvps.size).flatten]

          params = param_names.map {|pn| @store.addParam(pn)}

          feature = @store.addFeature(@gskey)
          feature.modifyParams("ADD", pvmap1)
          
          mappings = feature.params
          
          mappings.size.should == pvmap1.size
          
          feature.modifyParams("REPLACE", pvmap2)
          
          mappings = feature.params
          
          mappings.size.should == pvmap2.size
          
          pvmap2.each do |k,v|
            mappings.keys.should include(k)
            mappings[k].should == v
          end
        end

        it "should allow adding parameter/value mappings to existing mappings" do
          param_names = ("XAA".."XAZ").to_a
          param_values = param_names.map {|pn| pn.downcase}
          
          nvps = *param_names.zip(param_values)
          
          pvmap1 = Hash[*nvps.slice(0,5).flatten]
          pvmap2 = Hash[*nvps.slice(5,nvps.size).flatten]

          params = param_names.map {|pn| @store.addParam(pn)}

          feature = @store.addFeature(@gskey)
          feature.modifyParams("ADD", pvmap1)
          
          mappings = feature.params
          
          mappings.size.should == pvmap1.size
          
          feature.modifyParams("ADD", pvmap2)
          
          mappings = feature.params
          
          mappings.size.should == param_names.size
          
          param_names.zip(param_values).each do |k,v|
            mappings.keys.should include(k)
            mappings[k].should == v
          end
        end

        it "should replace preexisting mappings if their params appear in an ADD" do
          param_names = ("XAA".."XAZ").to_a
          param_values = param_names.map {|pn| pn.downcase}
          
          nvps = *param_names.zip(param_values)
          
          pvmap = Hash[*nvps.flatten]

          params = param_names.map {|pn| @store.addParam(pn)}

          feature = @store.addFeature(@gskey)
          feature.modifyParams("ADD", pvmap)
          
          mappings = feature.params
          
          mappings.size.should == pvmap.size
          
          expected_pvmap = pvmap.dup
          pvmap = {}
          
          param_names.slice(0,5).each do |pn|
            pvmap[pn] = pn.downcase.reverse
            expected_pvmap[pn] = pn.downcase.reverse
          end
          
          feature.modifyParams("ADD", pvmap)
          
          mappings = feature.params
          
          mappings.size.should == param_names.size
          
          expected_pvmap.each do |k,v|
            mappings.keys.should include(k)
            mappings[k].should == v
          end
        end

        it "should allow removing parameter/value mappings all at once" do
          param_names = ("XAA".."XAZ").to_a
          param_values = param_names.map {|pn| pn.downcase}
          
          pvmap = Hash[*param_names.zip(param_values).flatten]

          params = param_names.map {|pn| @store.addParam(pn)}

          feature = @store.addFeature(@gskey)
          feature.modifyParams("ADD", pvmap)
          
          mappings = feature.params
          
          mappings.size.should == pvmap.size

          feature.modifyParams("REMOVE", pvmap)
          
          mappings = feature.params
          
          mappings.size.should == 0
          
          param_names.zip(param_values).each do |k,v|
            mappings = feature.params
            mappings.keys.should_not include(k)
            mappings[k].should_not == v
          end
        end
        
        it "should allow removing parameter/value mappings one at a time" do
          param_names = ("XAA".."XAZ").to_a
          param_values = param_names.map {|pn| pn.downcase}
          
          pvmap = Hash[*param_names.zip(param_values).flatten]

          params = param_names.map {|pn| @store.addParam(pn)}

          feature = @store.addFeature(@gskey)
          feature.modifyParams("ADD", pvmap)

          mappings = feature.params
          old_size = mappings.size
          
          param_names.zip(param_values).each do |k,v|
            feature.modifyParams("REMOVE", {k=>v})
            mappings = feature.params
            mappings.size.should == old_size - 1
            mappings.keys.should_not include(k)
            
            old_size = mappings.size
          end
        end
        
        it "should give parameters default values when they are added as mapped to nil or false" do
          pending
        end

        it "should know which features are installed on a given node when those are installed in the default group" do
          dep_dests = []
          ["Oat Clustering", "Pony Accelerator", "High-Availability Stable", "Equine Management", "Low-Latency Saddle Provisioning"].each do |fn|
            dep_dests << @store.addFeature(fn)
          end

          node = @store.addNode("blah.local.")
          
          default = Group.DEFAULT_GROUP
          
          default.modifyFeatures("ADD", [dep_dests[0].name, dep_dests[2].name])
          
          ffn = Feature.features_for_node(node)
          
          ffn.should have(2).things
          
          [0,2].each do |num|
            ffn.map {|x| x.name}.should include(dep_dests[num].name)
          end
        end

        it "should know which features are installed on the default group" do
          dep_dests = []
          ["Oat Clustering", "Pony Accelerator", "High-Availability Stable", "Equine Management", "Low-Latency Saddle Provisioning"].each do |fn|
            dep_dests << @store.addFeature(fn)
          end
          
          default = Group.DEFAULT_GROUP
          
          default.modifyFeatures("ADD", [dep_dests[0].name, dep_dests[2].name])
          
          ffg = Feature.features_for_group(default)
          
          ffg.should have(2).things
          
          [0,2].each do |num|
            ffg.map {|x| x.name}.should include(dep_dests[num].name)
          end
        end

        it "should know which features are included in those installed on the default group" do
          dep_dests = []
          ["Oat Clustering", "Pony Accelerator", "High-Availability Stable", "Equine Management", "Low-Latency Saddle Provisioning"].each do |fn|
            dep_dests << @store.addFeature(fn)
          end
          
          default = Group.DEFAULT_GROUP
          
          dep_dests[0].modifyIncludedFeatures("ADD", [dep_dests[2].name])
          default.modifyFeatures("ADD", [dep_dests[0].name])
          
          ffg = Feature.features_for_group(default)
          
          ffg.should have(2).things
          
          [0,2].each do |num|
            ffg.map {|x| x.name}.should include(dep_dests[num].name)
          end
        end

        it "should know which features are depended upon by those installed on the default group" do
          dep_dests = []
          ["Oat Clustering", "Pony Accelerator", "High-Availability Stable", "Equine Management", "Low-Latency Saddle Provisioning"].each do |fn|
            dep_dests << @store.addFeature(fn)
          end
          
          default = Group.DEFAULT_GROUP
          
          dep_dests[0].modifyDepends("ADD", [dep_dests[2].name, dep_dests[4].name])
          default.modifyFeatures("ADD", [dep_dests[0].name])
          
          dfg = Feature.dependencies_for_group(default)
          
          dfg.should have(2).things
          
          [2,4].each do |num|
            dfg.map {|x| x.name}.should include(dep_dests[num].name)
          end
        end

        it "should know which features are installed on a given node when those are installed in the node's identity group" do
          dep_dests = []
          ["Oat Clustering", "Pony Accelerator", "High-Availability Stable", "Equine Management", "Low-Latency Saddle Provisioning"].each do |fn|
            dep_dests << @store.addFeature(fn)
          end

          node = @store.addNode("blah.local.")
          
          idgroup = node.idgroup
          
          idgroup.modifyFeatures("ADD", [dep_dests[0].name, dep_dests[2].name])
          
          ffn = Feature.features_for_node(node)
          
          ffn.should have(2).things
          
          [0,2].each do |num|
            ffn.map {|x| x.name}.should include(dep_dests[num].name)
          end
        end

        it "should know which features are installed on a given node when those are installed in the node's identity group" do
          dep_dests = []
          ["Oat Clustering", "Pony Accelerator", "High-Availability Stable", "Equine Management", "Low-Latency Saddle Provisioning"].each do |fn|
            dep_dests << @store.addFeature(fn)
          end

          node = @store.addNode("blah.local.")
          
          idgroup = node.idgroup
          
          idgroup.modifyFeatures("ADD", [dep_dests[0].name, dep_dests[2].name, dep_dests[3].name])
          
          ffn = Feature.features_for_node(node)
          
          ffn.should have(3).things
          
          [0,2,3].each do |num|
            ffn.map {|x| x.name}.should include(dep_dests[num].name)
          end
        end

        it "should know which features are installed on a given node when those are installed on a group that that node is a member of" do
          dep_dests = []
          ["Oat Clustering", "Pony Accelerator", "High-Availability Stable", "Equine Management", "Low-Latency Saddle Provisioning"].each do |fn|
            dep_dests << @store.addFeature(fn)
          end

          node = @store.addNode("blah.local.")
          group = @store.addExplicitGroup("Pony Users")
          
          group.modifyFeatures("ADD", [dep_dests[0].name, dep_dests[2].name, dep_dests[3].name])
          
          ffn = Feature.features_for_node(node)
          
          ffn.should have(0).things
          
          node.modifyMemberships("ADD", [group.name])

          ffn = Feature.features_for_node(node)
          
          ffn.should have(3).things
          
          [0,2,3].each do |num|
            ffn.map {|x| x.name}.should include(dep_dests[num].name)
          end
        end


        it "should know which features are installed on a given node when those are included in another feature installed on that node" do
          dep_dests = []
          ["Oat Clustering", "Pony Accelerator", "High-Availability Stable", "Equine Management", "Low-Latency Saddle Provisioning"].each do |fn|
            dep_dests << @store.addFeature(fn)
          end

          node = @store.addNode("blah.local.")
          
          idgroup = node.idgroup
          
          dep_dests[2].modifyIncludedFeatures("ADD", [dep_dests[3].name])
          
          idgroup.modifyFeatures("ADD", [dep_dests[0].name, dep_dests[2].name])
          
          ffn = Feature.features_for_node(node)
          
          ffn.should have(3).things
          
          [0,2,3].each do |num|
            ffn.map {|x| x.name}.should include(dep_dests[num].name)
          end
        end

        
        it "should be able to detect inclusion cycles" do
          dep_dests = []
          ["Oat Clustering", "Pony Accelerator", "High-Availability Stable", "Equine Management", "Low-Latency Saddle Provisioning"].each do |fn|
            dep_dests << @store.addFeature(fn)
          end
          
          dep_dests.each_cons(2) do |feature, dependent|
            feature.modifyIncludedFeatures("ADD", [dependent.name])
          end
          
          lambda {
            dep_dests[-1].modifyIncludedFeatures("ADD", [dep_dests[0].name])
          }.should raise_error
        end


        it "should be able to detect dependence cycles" do
          dep_dests = []
          ["Oat Clustering", "Pony Accelerator", "High-Availability Stable", "Equine Management", "Low-Latency Saddle Provisioning"].each do |fn|
            dep_dests << @store.addFeature(fn)
          end
          
          dep_dests.each_cons(2) do |feature, dependent|
            feature.modifyDepends("ADD", [dependent.name])
          end
          
          lambda {
            dep_dests[-1].modifyDepends("ADD", [dep_dests[0].name])
          }.should raise_error
        end
        
        [["include", "inclusion", :included_features, :modifyIncludedFeatures, true, :addFeature], ["depend on", "dependence", :depends, :modifyDepends, true, :addFeature], ["conflict with", "conflict", :conflicts, :modifyConflicts, false, :addFeature]].each do |verb,adjective,inspect_msg,modify_msg,order_preserving,create_dest_msg|

          fake_collection = Array
          nouns = create_dest_msg == :addFeature ? "features" : "subsystems"

          it "should #{verb} no other #{nouns} by default" do
            feature = @store.addFeature("Pony Accelerator")

            feature.send(inspect_msg).size.should == 0
          end

          it "should be able to #{verb} other #{nouns}" do
            dep_dests = []
            ["High-Availability Stable", "Equine Management", "Low-Latency Saddle Provisioning"].each do |fn|
              dep_dests << @store.send(create_dest_msg, fn)
            end

            feature = @store.addFeature("Pony Accelerator")

            feature.send(modify_msg, "ADD", fake_collection[*dep_dests.map {|f| f.name}])

            feature.send(inspect_msg).size.should == dep_dests.size
          end

          it "should be able to #{verb} the empty set of other #{nouns}" do
            dep_dests = []

            feature = @store.addFeature("Pony Accelerator")

            feature.send(modify_msg, "ADD", fake_collection[*dep_dests])

            feature.send(inspect_msg).size.should == dep_dests.size
          end

          it "should #{verb} additional #{nouns} idempotently" do
            dep_dests = []
            ["High-Availability Stable", "Equine Management", "Low-Latency Saddle Provisioning"].each do |fn|
              dep_dests << @store.send(create_dest_msg, fn)
            end

            feature = @store.addFeature("Pony Accelerator")

            feature.send(modify_msg, "ADD", fake_collection[*dep_dests.map {|f| f.name}])
            feature.send(inspect_msg).size.should == dep_dests.size

            feature.send(modify_msg, "ADD", fake_collection[*dep_dests.map {|f| f.name}])
            feature.send(inspect_msg).size.should == dep_dests.size

            observed_dests = feature.send(inspect_msg)
            dep_dests.each do |ef| 
              observed_dests.should include(ef.name)
            end
          end

          it "should #{verb} additional #{nouns} idempotently even if they appear multiple times in the same call" do
            dep_dests = []
            ["High-Availability Stable", "Equine Management", "Low-Latency Saddle Provisioning"].each do |fn|
              dep_dests << @store.send(create_dest_msg, fn)
            end

            feature = @store.addFeature("Pony Accelerator")

            supplied_dests = (dep_dests+dep_dests+dep_dests+dep_dests).sort_by {rand}

            feature.send(modify_msg, "ADD", fake_collection[*supplied_dests.map {|f| f.name}])
            feature.send(inspect_msg).size.should == dep_dests.size

            observed_dests = feature.send(inspect_msg)

            supplied_dests.uniq.each do |ef| 
              observed_dests.should include(ef.name)
            end
          end

          it "should be possible to remove #{nouns} from the #{adjective} list" do
            dep_dests = []
            ["High-Availability Stable", "Equine Management", "Low-Latency Saddle Provisioning"].each do |fn|
              dep_dests << @store.send(create_dest_msg, fn)
            end

            feature = @store.addFeature("Pony Accelerator")

            feature.send(modify_msg, "ADD", fake_collection[*dep_dests.map {|f| f.name}])

            feature.send(modify_msg, "REMOVE", fake_collection[*dep_dests.pop.name])

            observed_dests = feature.send(inspect_msg)
            dep_dests.each do |ef| 
              observed_dests.should include(ef.name)
            end
          end

          if order_preserving
            it "should #{verb} other #{nouns} in order" do
              dep_dests = []
              ["High-Availability Stable", "Equine Management", "Low-Latency Saddle Provisioning"].each do |fn|
                dep_dests << @store.send(create_dest_msg, fn)
              end

              feature = @store.addFeature("Pony Accelerator")

              feature.send(modify_msg, "ADD", fake_collection[*dep_dests.map {|f| f.name}])

              observed_dests = feature.send(inspect_msg)
              observed_dests.zip(dep_dests).each do |of,ef| 
                ef.name.should == of
              end
            end

            it "should replace #{adjective}s in order" do
              dep_dests = []
              ["High-Availability Stable", "Peer-to-peer Oat Store", "Equine Management", "Low-Latency Saddle Provisioning", "Alpheus", "Peneus"].sort_by { rand }.each do |fn|
                dep_dests << @store.send(create_dest_msg, fn)
              end

              feature = @store.addFeature("Pony Accelerator")

              feature.send(modify_msg, "REPLACE", fake_collection[*dep_dests.map {|f| f.name}])

              observed_dests = feature.send(inspect_msg)
              observed_dests.zip(dep_dests).each do |of,ef| 
                ef.name.should == of
              end
            end

            it "should #{verb} additional #{nouns} after all preexisting #{adjective}s" do
              dep_dests = []
              ["High-Availability Stable", "Equine Management", "Low-Latency Saddle Provisioning"].each do |fn|
                dep_dests << @store.send(create_dest_msg, fn)
              end

              feature = @store.addFeature("Pony Accelerator")

              feature.send(modify_msg, "ADD", fake_collection[*dep_dests.slice(0,2).map {|f| f.name}])

              feature.send(inspect_msg).size.should == dep_dests.slice(0,2).size

              observed_dests = feature.send(inspect_msg)
              observed_dests.zip(dep_dests.slice(0,2)).each do |of,ef| 
                ef.name.should == of
              end

              feature.send(modify_msg, "ADD", fake_collection[dep_dests[-1].name])
              feature.send(inspect_msg).size.should == dep_dests.size

              observed_dests = feature.send(inspect_msg)
              observed_dests.zip(dep_dests).each do |of,ef| 
                ef.name.should == of
              end
            end
          end
        end

        it "should properly handle default values in the highest-priority feature assignment" do
          param = @store.addParam("FOO")
          param.setDefault("BAR")
          
          feature = @store.addFeature("FooFeature")
          feature.modifyParams("ADD", {"FOO"=>0}, {})
          
          node = @store.addNode("blah.local.")
          node.idgroup.modifyFeatures("ADD", [feature.name], {})
          
          config = node.getConfig
          
          node.validate.should == true
          
          config.should have_key("FOO")
          config["FOO"].should == "BAR"
        end
        
        it "should properly handle default values in lower-priority feature assignments" do
          param = @store.addParam("FOO")
          param.setDefault("BAR")
          
          feature1 = @store.addFeature("FooFeature")
          feature1.modifyParams("ADD", {"FOO"=>"ARGH"}, {})

          feature2 = @store.addFeature("BarFeature")
          feature2.modifyParams("ADD", {"FOO"=>0}, {})
          
          node = @store.addNode("blah.local.")
          node.idgroup.modifyFeatures("ADD", [feature2.name, feature1.name], {})
          
          config = node.getConfig
          
          node.validate.should == true
          
          config.should have_key("FOO")
          config["FOO"].should == "BAR"
        end
        
        it "should identify invalid features" do
          feature_list = ("cat".."eel").to_a.sort_by {rand}
          bogus_names = feature_list.slice!(0, feature_list.index("dog"))
          
          feature_list.each {|feature| @store.addFeature(feature)}
          Feature.select_invalid(bogus_names).should == bogus_names
        end

        it "should not identify valid features as invalid" do
          feature_list = ("cat".."eel").to_a.sort_by {rand}
          bogus_names = feature_list.slice!(0, feature_list.index("dog"))
          
          feature_list.each {|feature| @store.addFeature(feature)}
          Feature.select_invalid(feature_list).should == []
        end

        it "should pick out the invalid feature names from a list of valid and invalid features" do
          feature_list = ("cat".."eel").to_a.sort_by {rand}
          bogus_names = feature_list.slice!(0, feature_list.index("dog"))
          
          feature_list.each {|feature| @store.addFeature(feature)}
          invalids = Set[*Feature.select_invalid(feature_list + bogus_names)]
          
          Set[*bogus_names].should == invalids
          (Set[*feature_list] & invalids).size.should == 0
        end

      end

    end
  end
end
