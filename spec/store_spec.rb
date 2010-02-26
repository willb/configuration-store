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
        
        # XXX:  the internal versions of these should probably go in a module to be mixed in to the respective spec files
        {Feature=>:AddFeature, Group=>:AddExplicitGroup, Node=>:AddNode, Parameter=>:AddParam, Subsystem=>:AddSubsys}.each do |klass, instantiate_klass_msg|

          {"internal"=>Proc.new {|store,namelist| klass.select_invalid(namelist)},
           "API"=>Proc.new {|store,namelist| store.send("check#{klass.name}Validity", FakeSet[*namelist]).keys}}.each do |kind, callable|
          
            it "should identify invalid #{klass.name.downcase}s with #{kind} methods" do
              bogus_names = @entity_list.slice!(0, @entity_list.size / 3)
  
              @entity_list.each {|feature| @store.send(instantiate_klass_msg, feature)}
              Set[*callable.call(@store, bogus_names)].should == Set[*bogus_names]
            end
  
            it "should not identify valid #{klass.name.downcase}s as invalid with #{kind} methods" do
              bogus_names = @entity_list.slice!(0, @entity_list.size / 3)
  
              @entity_list.each {|feature| @store.send(instantiate_klass_msg, feature)}
              Set[*callable.call(@store, @entity_list)].should == Set[]
            end
  
            it "should pick out the invalid #{klass.name.downcase} names from a list of valid and invalid #{klass.name.downcase}s with #{kind} methods" do
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
