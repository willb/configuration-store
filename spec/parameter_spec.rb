require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module Mrg
  module Grid
    module Config
      describe Parameter do
        before(:each) do
          setup_rhubarb
          @store = Store.new
          @add_msg = :AddParam
          @find_msg = :GetParam
          @gskey = "BIOTECH"
        end
        
        after(:each) do
          teardown_rhubarb
        end
        
        def test_getter_and_setter(setmsg, getmsg, values, key=nil)
          key ||= @gskey
          param = @store.send(@add_msg, key)
          
          values.each do |val|
            param = @store.send(@find_msg, key)
            param.send(setmsg, val)
            
            param = @store.send(@find_msg, key)
            param.send(getmsg).should == val
          end
        end

        it "enables creating a parameter" do
          param = @store.AddParam("BIOTECH")
          param.name.should == "BIOTECH"
        end

        it "enables finding a created parameter" do
          param = @store.AddParam("BIOTECH")
          param = @store.GetParam("BIOTECH")
          
          param.name.should == "BIOTECH"
          
          
        end
        
        it "enables setting a parameter's type" do
          test_getter_and_setter(:SetType, :GetType, ["int", "string", "timestamp", "hostname"])
        end
        
        it "enables setting a parameter's default value" do
          test_getter_and_setter(:SetDefault, :GetDefault, ("The quick brown fox jumps over the lazy dad".."The quick brown fox jumps over the lazy dog"))
        end
        
        it "enables setting a parameter's description" do
          vals = ["Does anyone know what this does?", "Perhaps not.", "All right, then."]
          test_getter_and_setter(:SetDescription, :GetDescription, vals)
        end
        
        it "enables setting a parameter's visibility level" do
          test_getter_and_setter(:SetVisibilityLevel, :GetVisibilityLevel, (0..12))
        end

        it "enables setting a parameter's requires-restart property" do
          test_getter_and_setter(:SetRequiresRestart, :GetRequiresRestart, [true, false])
        end

        
      end
    end
  end
end
