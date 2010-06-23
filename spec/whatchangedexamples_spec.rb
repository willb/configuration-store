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

        def self.PARAM(x)
          [:PARAM, x]
        end

        def self.VALUE(x)
          [:VALUE, x]
        end

        def self.domain(x)
          x[0]
        end

        [
         {:before=>{}, :after=>{PARAM(:a)=>VALUE(:a)}, :expected_diff=>[PARAM(:a)], :description=>"when a param is set in AFTER but not in BEFORE"},
         {:before=>{PARAM(:a)=>VALUE(:a)}, :after=>{}, :expected_diff=>[PARAM(:a)], :description=>"when a param is set in BEFORE but not in AFTER"},
         {:before=>{PARAM(:a)=>VALUE(:a)}, :after=>{PARAM(:a)=>VALUE(:a)}, :expected_diff=>[], :description=>"when a param is set identically in AFTER and in BEFORE"},
         {:before=>{PARAM(:a)=>VALUE(:a)}, :after=>{PARAM(:a)=>VALUE(:b)}, :expected_diff=>[PARAM(:a)], :description=>"when a param is set in AFTER, but to a different value than in BEFORE"},
         {:before=>{PARAM(:a)=>VALUE(:a), PARAM(:b)=>VALUE(:b)}, :after=>{PARAM(:a)=>VALUE(:a)}, :expected_diff=>[PARAM(:b)], :description=>"when the param set for BEFORE is a strict superset of that for AFTER and common params have common values"},
         {:before=>{PARAM(:a)=>VALUE(:a), PARAM(:b)=>VALUE(:b)}, :after=>{PARAM(:a)=>VALUE(:c)}, :expected_diff=>[PARAM(:a), PARAM(:b)], :description=>"when the param set for BEFORE is a strict superset of that for AFTER and common params do not have common values"},

         {:after=>{PARAM(:a)=>VALUE(:a), PARAM(:b)=>VALUE(:b)}, :before=>{PARAM(:a)=>VALUE(:a)}, :expected_diff=>[PARAM(:b)], :description=>"when the param set for BEFORE is a strict subset of that for AFTER and common params have common values"},
         {:after=>{PARAM(:a)=>VALUE(:a), PARAM(:b)=>VALUE(:b)}, :before=>{PARAM(:a)=>VALUE(:c)}, :expected_diff=>[PARAM(:a), PARAM(:b)], :description=>"when the param set for BEFORE is a strict subset that for AFTER and common params do not have common values"},
         {:before=>{PARAM(:a)=>VALUE(:a), PARAM(:b)=>VALUE(:b)}, :after=>{PARAM(:a)=>VALUE(:a), PARAM(:c)=>VALUE(:c)}, :expected_diff=>[PARAM(:b), PARAM(:c)], :description=>"when the param sets for BEFORE and AFTER are intersecting but neither is a strict superset of the other, and common params have common values"},
         {:before=>{PARAM(:a)=>VALUE(:a), PARAM(:b)=>VALUE(:b)}, :after=>{PARAM(:a)=>VALUE(:d), PARAM(:c)=>VALUE(:c)}, :expected_diff=>[PARAM(:a), PARAM(:b), PARAM(:c)], :description=>"when the param sets for BEFORE and AFTER are intersecting but neither is a strict superset of the other, and common params do not have common values"},
         {:before=>{PARAM(:a)=>VALUE(:a), PARAM(:b)=>VALUE(:b)}, :after=>{PARAM(:d)=>VALUE(:d), PARAM(:c)=>VALUE(:c)}, :expected_diff=>[PARAM(:a), PARAM(:b), PARAM(:c), PARAM(:d)], :description=>"when the param sets for BEFORE and AFTER are disjoint"}
        ].each do |exampleinfo|
          [:identity_group, :default_group, :installed_feature].each do |whatchanged|
            [true,false].each do |dorestart|

              it "should properly identify #{dorestart ? "restart" : "reconfigure"}-parameter diffs between two changed versions when the #{whatchanged} changed and #{exampleinfo[:description]}" do
                setup_whatchanged_tests
                c_before, c_after, expected_diff = unify_param_expectations(exampleinfo[:before], exampleinfo[:after], exampleinfo[:expected_diff], dorestart)
                node = @store.addNode("example.local.")
                feature = @store.addFeature("Example Feature")
                node.identity_group.modifyFeatures("ADD", [feature.name], {})

                thing_to_change = case whatchanged
                when :identity_group then node.identity_group
                when :default_group then Group.DEFAULT_GROUP
                when :installed_feature then feature
                end

                thing_to_change.modifyParams("REPLACE", c_before)
                @store.activateConfiguration
                old_version = node.last_updated_version

                thing_to_change.modifyParams("REPLACE", c_after)
                @store.activateConfiguration
                new_version = node.last_updated_version

                params, restart, reconfig = node.whatChanged(old_version, new_version)
                (params.sort - %w{WALLABY_CONFIG_VERSION}).should == expected_diff.sort

                sss = expected_diff.map {|prm| Subsystem.s_for_param(prm).map {|ss| ss.name}}.flatten.sort.uniq
                if dorestart
                  reconfig.size.should == 0
                  restart.sort.uniq.should == sss
                else
                  restart.size.should == 0
                  reconfig.sort.uniq.should == sss
                end
              end
            end

            it "should properly identify reconfigure-parameter diffs between two changed versions when the #{whatchanged} changed, the parameters in question have been changed from restart-parameters, and #{exampleinfo[:description]}" do
              setup_whatchanged_tests
              c_before, c_after, expected_diff = unify_param_expectations(exampleinfo[:before], exampleinfo[:after], exampleinfo[:expected_diff], true)
              node = @store.addNode("example.local.")
              feature = @store.addFeature("Example Feature")
              node.identity_group.modifyFeatures("ADD", [feature.name], {})

              thing_to_change = case whatchanged
              when :identity_group then node.identity_group
              when :default_group then Group.DEFAULT_GROUP
              when :installed_feature then feature
              end

              thing_to_change.modifyParams("REPLACE", c_before)
              @store.activateConfiguration
              old_version = node.last_updated_version

              # change all of the parameters involved to reconfig-parameters
              (c_before.keys | c_after.keys).each do |prm|
                @store.getParam(prm).setRequiresRestart(false)
              end

              thing_to_change.modifyParams("REPLACE", c_after)
              @store.activateConfiguration
              new_version = node.last_updated_version

              params, restart, reconfig = node.whatChanged(old_version, new_version)
              (params.sort - %w{WALLABY_CONFIG_VERSION}).should == expected_diff.sort

              sss = expected_diff.map {|prm| Subsystem.s_for_param(prm).map {|ss| ss.name}}.flatten.sort.uniq

              restart.size.should == 0
              reconfig.sort.uniq.should == sss
            end
          
          end
          
          [:identity_group, :default_group].each do |whatchanged|
            [true,false].each do |dorestart|

              it "should properly identify #{dorestart ? "restart" : "reconfigure"}-parameter diffs between two changed versions when a feature set on the #{whatchanged} changed and #{exampleinfo[:description]}" do
                setup_whatchanged_tests
                c_before, c_after, expected_diff = unify_param_expectations(exampleinfo[:before], exampleinfo[:after], exampleinfo[:expected_diff], dorestart)
                node = @store.addNode("example.local.")
                before_feature = @store.addFeature("Before Feature")
                after_feature = @store.addFeature("After Feature")

                before_feature.modifyParams("REPLACE", c_before)
                after_feature.modifyParams("REPLACE", c_after)

                thing_to_change = case whatchanged
                when :identity_group then node.identity_group
                when :default_group then Group.DEFAULT_GROUP
                end

                thing_to_change.modifyFeatures("REPLACE", [before_feature.name], {})
                @store.activateConfiguration
                old_version = node.last_updated_version

                thing_to_change.modifyFeatures("REPLACE", [after_feature.name], {})
                @store.activateConfiguration
                new_version = node.last_updated_version

                params, restart, reconfig = node.whatChanged(old_version, new_version)
                (params.sort - %w{WALLABY_CONFIG_VERSION}).should == expected_diff.sort

                sss = expected_diff.map {|prm| Subsystem.s_for_param(prm).map {|ss| ss.name}}.flatten.sort.uniq
                if dorestart
                  reconfig.size.should == 0
                  restart.sort.uniq.should == sss
                else
                  restart.size.should == 0
                  reconfig.sort.uniq.should == sss
                end
              end
            end

            it "should properly identify reconfigure-parameter diffs between two changed versions when the feature set on the #{whatchanged} changed, the parameters in question have been changed from restart-parameters, and #{exampleinfo[:description]}" do
              setup_whatchanged_tests
              c_before, c_after, expected_diff = unify_param_expectations(exampleinfo[:before], exampleinfo[:after], exampleinfo[:expected_diff], true)
              node = @store.addNode("example.local.")
              before_feature = @store.addFeature("Before Feature")
              after_feature = @store.addFeature("After Feature")

              before_feature.modifyParams("REPLACE", c_before)
              after_feature.modifyParams("REPLACE", c_after)

              thing_to_change = case whatchanged
              when :identity_group then node.identity_group
              when :default_group then Group.DEFAULT_GROUP
              end

              thing_to_change.modifyFeatures("REPLACE", [before_feature.name], {})
              @store.activateConfiguration
              old_version = node.last_updated_version

              # change all of the parameters involved to reconfig-parameters
              (c_before.keys | c_after.keys).each do |prm|
                @store.getParam(prm).setRequiresRestart(false)
              end

              thing_to_change.modifyFeatures("REPLACE", [after_feature.name], {})
              @store.activateConfiguration
              new_version = node.last_updated_version

              params, restart, reconfig = node.whatChanged(old_version, new_version)
              (params.sort - %w{WALLABY_CONFIG_VERSION}).should == expected_diff.sort

              sss = expected_diff.map {|prm| Subsystem.s_for_param(prm).map {|ss| ss.name}}.flatten.sort.uniq

              restart.size.should == 0
              reconfig.sort.uniq.should == sss
            end
          end
        end
      end
    end
  end
end