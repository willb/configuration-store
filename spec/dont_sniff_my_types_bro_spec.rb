require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'digest/md5'

module Mrg
  module Grid
    module Config

      describe Node do
        before(:each) do
          setup_rhubarb
          @store = Store.new
          reconstitute_db
        end
        
        after(:each) do
          teardown_rhubarb
        end
        
        include BaseDBFixture

        [["int", "0001234567890"], ["float", "1.100"]].each do |kind, expected_val|
          it "should not convert string parameter values to #{kind}s, even if they look like #{kind}s" do
            @store.addParam("FOO")
            ff = @store.addExplicitGroup("Foo Floaters")
            ff.modifyParams("ADD", {"FOO"=>expected_val}, {})
            ff.getConfig["FOO"].should == expected_val
          end
        end
      end
    end
  end
end
