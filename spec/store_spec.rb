require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module Mrg
  module Grid
    module Config
      describe Store do
        before(:each) do
          setup_rhubarb
          @entity_list = ("ack".."bar").to_a.sort_by {rand} # It's a trap
          @store = Store.new
        end

        after(:each) do
          @entity_list = []
          teardown_rhubarb
        end

        it "should validate empty configurations" do
          explain, warnings = @store.activateConfiguration
          explain.should == {}
          warnings.grep(/No nodes in configuration/).should_not == []
        end

        
        it "should not validate nodeless configurations that do not provide features depended upon by enabled features (in the default group)" do
          features = %w{FooFeature BarFeature}.map {|fname| @store.addFeature(fname)}
          features[0].modifyDepends("ADD", Array[features[1].name], {})

          Group.DEFAULT_GROUP.modifyFeatures("ADD", Array[features[0].name], {})

          explain, warnings = @store.activateConfiguration
          explain.should_not == {}
          explain["+++DEFAULT"][Node::BROKEN_FEATURE_DEPS].should include("BarFeature")
          warnings.grep(/No nodes in configuration/).should_not == []
        end

        it "should not validate nodeless configurations that do not provide values for must-change parameters" do
          param = @store.addParam("FOO")
          param.setMustChange(true)

          feature = @store.addFeature("FooFeature")
          feature.modifyParams("ADD", {"FOO"=>0}, {})

          Group.DEFAULT_GROUP.modifyFeatures("ADD", Array[feature.name], {})

          explain, warnings = @store.activateConfiguration
          explain.should_not == {}
          explain["+++DEFAULT"][Node::UNSET_MUSTCHANGE_PARAMS].should include("FOO")
          warnings.grep(/No nodes in configuration/).should_not == []
        end
        
        
        # XXX:  the internal versions of these should probably go in a module to be mixed in to the respective spec files
        {Feature=>:addFeature, Group=>:addExplicitGroup, Node=>:addNode, Parameter=>:addParam, Subsystem=>:addSubsys}.each do |klass, instantiate_klass_msg|

          {"internal"=>Proc.new {|store,namelist| klass.select_invalid(namelist)},
           "API"=>Proc.new {|store,namelist| store.send("check#{klass.name.split("::").pop}Validity", Array[*namelist])}}.each do |kind, callable|
          
            it "should identify invalid #{klass.name.split("::").pop.downcase}s with #{kind} methods" do
              bogus_names = @entity_list.slice!(0, @entity_list.size / 3)
  
              @entity_list.each {|feature| @store.send(instantiate_klass_msg, feature)}
              Set[*callable.call(@store, bogus_names)].should == Set[*bogus_names]
            end
  
            it "should not identify valid #{klass.name.split("::").pop.downcase}s as invalid with #{kind} methods" do
              bogus_names = @entity_list.slice!(0, @entity_list.size / 3)
  
              @entity_list.each {|feature| @store.send(instantiate_klass_msg, feature)}
              Set[*callable.call(@store, @entity_list)].should == Set[]
            end
  
            it "should pick out the invalid #{klass.name.split("::").pop.downcase} names from a list of valid and invalid #{klass.name.split("::").pop.downcase}s with #{kind} methods" do
              bogus_names = @entity_list.slice!(0, @entity_list.size / 3)
  
              @entity_list.each {|feature| @store.send(instantiate_klass_msg, feature)}
              invalids = Set[*callable.call(@store, @entity_list + bogus_names)]
  
              Set[*bogus_names].should == invalids
              (Set[*@entity_list] & invalids).size.should == 0
            end
          end
        end
      end
    end
  end
end
