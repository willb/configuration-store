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
        
        include BaseDBFixture
        include WhatChangedTester
        
        # it "should have a better example name than this!"
        it "should not exhibit Rob's failure case of 6/23/2010" do
          setup_whatchanged_tests
          
          feature_names_1 = %w{Master QMF NodeAccess CentralManager}
          feature_names_2 = %w{ExecuteNode}
          param_names = %w{DAEMON_LIST}
          
          params = []
          
          # make sure that we have all of the features we need for this test
          (feature_names_1 + feature_names_2).each do |fn|
            f = @store.getFeature(fn)
            unless f
              pending "can't find feature #{fn} in the base db"
              return
            end
          end
          
          # make sure that we have all of the params we need for this test
          param_names.each do |pn|
            p = @store.getParam(pn)
            unless p
              pending "can't find param #{pn} in the base db"
              return
            end

            params << p
          end
          
          # create a node
          node = @store.addNode("example.local.")
          
          # enable the first set of features
          Group.DEFAULT_GROUP.modifyFeatures("ADD", feature_names_1, {})
          
          # set must-change params
          Group.DEFAULT_GROUP.modifyParams("ADD", {"ALLOW_WRITE"=>"localhost", "QMF_BROKER_HOST"=>"localhost", "CONDOR_HOST"=>"localhost", "ALLOW_READ"=>"localhost"}, {})
          
          # activate and record version info
          @store.activateConfiguration
          old_version = node.last_updated_version
          
          # make DAEMON_LIST a non-mustchange parameter
          params.each {|p| p.setRequiresRestart(false)}
          
          # enable ExecuteNode on the default group
          Group.DEFAULT_GROUP.modifyFeatures("ADD", feature_names_2, {})
          @store.activateConfiguration

          new_version = node.last_updated_version

          changed_params, changed_restart, changed_reconfig = node.whatChanged(old_version, new_version)
          
          # XXX:  I'd rather not hard-code these in, but this is fine for now.
          changed_restart.should == %w{startd}
          changed_reconfig.should == %w{master}
        end
      end
    end
  end
end