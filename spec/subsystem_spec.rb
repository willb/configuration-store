require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module Mrg
  module Grid
    module Config
      describe Subsystem do
        before(:each) do
          setup_rhubarb
          @store = Store.new
          @add_msg = :AddSubsys
          @find_msg = :GetSubsys
          @gskey = "ha_cruftd"
        end
        
        after(:each) do
          teardown_rhubarb
        end
        
        include DescribeGetterAndSetter

        it "enables creating a subsystem" do
          subsys = @store.AddSubsys(@gskey)
          subsys.name.should == @gskey
        end

        it "disallows creating a subsystem with a name already in use" do
          subsys = @store.AddSubsys(@gskey)
          lambda { @store.AddSubsys(@gskey) }.should raise_error
        end


        it "enables finding a created subsystem" do
          subsys = @store.AddSubsys(@gskey)
          subsys = @store.GetSubsys(@gskey)
          
          subsys.name.should == @gskey
        end
        
        it "should accept additional implicated parameters" do
          param_names = ("XAA".."XAZ").to_a
          params = param_names.map {|pn| @store.AddParam(pn)}
          ss = @store.AddSubsys(@gskey)
          old_size = 0
          
          param_names.each do |k|
            ss.ModifyParams("ADD", {k=>true})
            mappings = ss.GetParams
            mappings.size.should == old_size + 1
            mappings.keys.should include(k)
            
            old_size = mappings.size
          end
        end
        
        it "should accept sets of additional implicated parameters" do
          param_names = ("XAA".."XAZ").to_a
          param_values = [true] * param_names.size
          
          pvmap = Hash[*param_names.zip(param_values).flatten]

          params = param_names.map {|pn| @store.AddParam(pn)}

          ss = @store.AddSubsys(@gskey)
          ss.ModifyParams("ADD", pvmap)
          
          mappings = ss.GetParams
          
          mappings.size.should == pvmap.size
          
          param_names.each do |k|
            mappings.keys.should include(k)
          end
        end
        
        it "should allow removing implicated parameters" do
          pending
        end

        it "should allow replacing the implicated parameter set" do
          pending
        end
        
      end
    end
  end
end
