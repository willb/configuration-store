require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module Mrg
  module Grid
    module Config
      describe Feature do
        
        before(:each) do
          setup_rhubarb
          @store = Store.new
          @add_msg = :AddFeature
          @find_msg = :GetFeature
          @gskey = "MORE_PONIES"
        end

        after(:each) do
          teardown_rhubarb
        end

        include DescribeGetterAndSetter
        
        it "should be instantiable" do
          feature = @store.AddFeature(@gskey)
          @store.GetFeature(@gskey).row_id == feature.row_id
        end
        
        it "should allow setting a feature's name" do
          vals = ["Fewer ponies", "Some ponies", "No ponies"]
          feature = @store.AddFeature(@gskey)

          vals.each do |val|
            old_rid = feature.row_id
            feature.SetName(val)
            
            feature = @store.GetFeature(val)
            feature.row_id.should == old_rid
          end
        end
        
        it "should not allow creating a feature's with a taken name" do
          feature = @store.AddFeature(@gskey)
          lambda { feature2 = @store.AddFeature(@gskey) }.should raise_error
          
        end
        
        it "should not allow setting a feature's name to a taken name" do
          feature = @store.AddFeature(@gskey)
          feature2 = @store.AddFeature("Fewer ponies")
          
          lambda { feature2.SetName(@gskey) }.should raise_error
        end
        
        it "should allow adding parameter/value mappings one at a time" do
          param_names = ("XAA".."XAZ").to_a
          param_values = param_names.map {|pn| pn.downcase}
          params = param_names.map {|pn| @store.AddParam(pn)}
          feature = @store.AddFeature(@gskey)
          old_size = 0
          
          param_names.zip(param_values).each do |k,v|
            feature.ModifyParams("ADD", {k=>v})
            mappings = feature.GetParams
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

          params = param_names.map {|pn| @store.AddParam(pn)}

          feature = @store.AddFeature(@gskey)
          feature.ModifyParams("ADD", pvmap)
          
          mappings = feature.GetParams
          
          mappings.size.should == pvmap.size
          
          param_names.zip(param_values).each do |k,v|
            mappings.keys.should include(k)
            mappings[k].should == v
          end
        end

        it "should allow removing parameter/value mappings all at once" do
          param_names = ("XAA".."XAZ").to_a
          param_values = param_names.map {|pn| pn.downcase}
          
          pvmap = Hash[*param_names.zip(param_values).flatten]

          params = param_names.map {|pn| @store.AddParam(pn)}

          feature = @store.AddFeature(@gskey)
          feature.ModifyParams("ADD", pvmap)
          
          mappings = feature.GetParams
          
          mappings.size.should == pvmap.size

          feature.ModifyParams("REMOVE", pvmap)
          
          mappings = feature.GetParams
          
          mappings.size.should == 0
          
          param_names.zip(param_values).each do |k,v|
            mappings = feature.GetParams
            mappings.keys.should_not include(k)
            mappings[k].should_not == v
          end
        end
        
        it "should allow removing parameter/value mappings one at a time" do
          param_names = ("XAA".."XAZ").to_a
          param_values = param_names.map {|pn| pn.downcase}
          
          pvmap = Hash[*param_names.zip(param_values).flatten]

          params = param_names.map {|pn| @store.AddParam(pn)}

          feature = @store.AddFeature(@gskey)
          feature.ModifyParams("ADD", pvmap)

          mappings = feature.GetParams
          old_size = mappings.size
          
          param_names.zip(param_values).each do |k,v|
            feature.ModifyParams("REMOVE", {k=>v})
            mappings = feature.GetParams
            mappings.size.should == old_size - 1
            mappings.keys.should_not include(k)
            
            old_size = mappings.size
          end
        end
        
      end
    end
  end
end
