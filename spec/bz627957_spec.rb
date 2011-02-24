require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'digest/md5'

module Mrg
  module Grid
    module Config

      describe Store do
        before(:each) do
          setup_rhubarb
          @store = Store.new

          @red = @store.addParam("RED")
          @red.setMustChange(true)
          @blue = @store.addFeature("Blue")
          @blue.modifyParams("ADD", {"RED"=>"0"}, {})
          @purple = @store.addFeature("Purple")
          @purple.modifyIncludedFeatures("ADD", ["Blue"], {})
        end
        
        after(:each) do
          teardown_rhubarb
        end
        
        include BaseDBFixture
        
        it "should require values for parameters in included features" do
          params = @purple.explain()
          params.keys.should include("RED")
        end
      end
    end
  end
end
