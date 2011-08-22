require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'digest/md5'

module Mrg
  module Grid
    module Config

      describe Node do
        before(:each) do
          setup_rhubarb
          @store = Store.new
        end
        
        after(:each) do
          teardown_rhubarb
        end
        
        it "should create missing requested nodes" do
          @store.should_receive(:createNode).with("foo", false)
          @store.getNode("foo")
        end
      end
    end
  end
end
