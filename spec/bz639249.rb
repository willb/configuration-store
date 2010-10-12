# Description of problem:
# $ condor_configure_pool --default-group -l
# Group "Internal Default Group":
# Group ID: 1
# Name: Internal Default Group
# Features (priority: name):
#   0: NodeAccess
#   1: Master
# Parameters:
#   ALLOW_WRITE = *
#   CONDOR_HOST = 127.0.0.1
#   ALLOW_READ = *
# 
# $ condor_config_val KILL
# (CurrentTime - EnteredCurrentActivity) > 10 * 60
# 
# It applies parameter value:
# $ condor_configure_pool --default-group -a -f DedicatedResource
# ...
# 
# $ condor_config_val KILL
# False
# 
# It doesn't apply parameter value:
# $ condor_configure_pool --default-group -a -f ExecuteNode
# ...
# 
# $ condor_config_val KILL
# False
# 
# $ condor_configure_pool --default-group -d -f DedicatedResource
# ...
# 
# $ condor_config_val KILL
# (CurrentTime - EnteredCurrentActivity) > 10 * 60
# 
# and from base-db file:
# name: ExecuteNode
# params:
#   KILL: $(ActivityTimer) > $(MaxVacateTime)
# 
# 
# Version-Release number of selected component (if applicable):
# python-condorutils-1.4-5.el5
# condor-wallaby-tools-3.6-5.el5
# condor-wallaby-base-db-1.4-5.el5
# condor-debuginfo-7.4.4-0.16.el5
# condor-7.4.4-0.16.el5
# condor-wallaby-client-3.6-5.el5
# wallaby-0.9.18-2.el5
# 
# How reproducible:
# 100%
# 
# Steps to Reproduce:
# above
# 
# Actual results:
# It doesn't apply parameter value from feature which is installed after feature
# with same parameter but with different value.
# 
# Expected results:
# It will apply parameter value from feature which is installed after feature
# with same parameter but with different value.

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
        
        it "should apply parameter values properly for the highest-priority feature in the default group" do
          node = @store.addNode("fugazi.local.")
          
          @store.getDefaultGroup().modifyFeatures("ADD", %w{NodeAccess Master}, {})
          
          # The default value for KILL is "$(ActivityTimer) > $(MaxVacateTime)"
          # ExecuteNode explicitly sets KILL to "$(ActivityTimer) > $(MaxVacateTime)"
          # DedicatedResource explicitly sets KILL to "False"
          # Nothing else in the default db sets KILL
          
          kill_prm = Parameter.find_first_by_name("KILL")
          
          kill_prm.should_not == nil
          
          @store.activateConfiguration
          
          @store.getDefaultGroup().getConfig.should_not == {}
          
          @store.getDefaultGroup().getConfig["KILL"].should == nil
          
          @store.getDefaultGroup().modifyFeatures("REPLACE", %w{ExecuteNode NodeAccess Master}, {})

          @store.activateConfiguration
          
          @store.getDefaultGroup().getConfig["KILL"].should == Feature.find_first_by_name("ExecuteNode").params["KILL"]
          
          @store.getDefaultGroup().modifyFeatures("REPLACE", %w{DedicatedResource ExecuteNode NodeAccess Master}, {})

          @store.activateConfiguration
          
          @store.getDefaultGroup().getConfig["KILL"].should == Feature.find_first_by_name("DedicatedResource").params["KILL"]
          
          @store.getDefaultGroup().modifyFeatures("REPLACE", %w{ExecuteNode NodeAccess Master}, {})

          @store.activateConfiguration
          
          @store.getDefaultGroup().getConfig["KILL"].should == Feature.find_first_by_name("ExecuteNode").params["KILL"]
        end
      end
    end
  end
end