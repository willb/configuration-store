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

        {"group"=>:addExplicitGroup, "node"=>:addNode, "feature"=>:addFeature, "node"=>:addNode, "unprovisioned node"=>:getNode, "parameter"=>:addParam, "subsystem"=>:addSubsys}.each do |what, msg|
          it "should not allow creating a #{what} with an empty name" do
            lambda {@store.send(msg, "")}.should raise_error
          end
        end
      end
    end
  end
end
