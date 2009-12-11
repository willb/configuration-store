require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module Mrg
  module Grid
    module Config
      describe Parameter do
        before(:each) do
          setup_rhubarb
          @store = Store.new
        end
        
        after(:each) do
          teardown_rhubarb
        end

        it "should be possible to create a parameter" do
          param = @store.AddParam("BIOTECH")
          param.name.should == "BIOTECH"
        end
      end
    end
  end
end
