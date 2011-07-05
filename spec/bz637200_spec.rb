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
        include WhatChangedTester
        
        it "should restart the condor_master on unprovisioned nodes when security settings are applied in the default group" do
          Group.DEFAULT_GROUP.modifyParams("ADD", {"SEC_DEFAULT_AUTHENTICATION_METHODS"=>"by-magic"})
          @store.activateConfiguration

          node = @store.getNode("unprovisioned.local.")
          old_version = node.last_updated_version

          @store.activateConfiguration
          new_version = node.last_updated_version

          expected_diff = %w{SEC_DEFAULT_AUTHENTICATION_METHODS}
          params, restart, reconfig = node.whatChanged(0, new_version)

          sss = expected_diff.map {|prm| Subsystem.s_for_param(prm).map {|ss| ss.name}}.flatten.sort.uniq

          collection = @store.getParam("SEC_DEFAULT_AUTHENTICATION_METHODS").requires_restart ? restart : reconfig

          (params.sort - %w{WALLABY_CONFIG_VERSION}).should == expected_diff.sort
          
          collection.size.should == 1
          collection.sort.uniq.should == sss
        end
      end
    end
  end
end
