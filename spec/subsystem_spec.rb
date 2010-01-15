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
          pending
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
