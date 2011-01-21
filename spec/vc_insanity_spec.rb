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
        
        it "should not change existing versioned configs when loading a new snapshot" do
          feature = @store.getFeature("Master")
          node = @store.addNode("foo")

          Group.DEFAULT_GROUP.modifyFeatures("ADD", %w{Master NodeAccess}, {})
          Group.DEFAULT_GROUP.modifyParams("ADD", {"CONDOR_HOST"=>"localhost", "ALLOW_WRITE"=>"localhost", "ALLOW_READ"=>"localhost"}, {})
          
          @store.makeSnapshot("pre")

          @store.addFeature("TestFeature").modifyIncludedFeatures("ADD", %w{ExecuteNode}, {})
          
          node.identity_group.modifyFeatures("ADD", %w{TestFeature}, {})
          
          @store.activateConfiguration.should == [{}, []]

          @store.makeSnapshot("post")

          nv = node.last_updated_version
          config_post = node.getConfig("version"=>nv)

          @store.loadSnapshot("pre")

          config_pre = node.getConfig("version"=>nv)

          config_post.keys.sort.should == config_pre.keys.sort

          config_post.keys.each do |k|
            config_post[k].should == config_pre[k]
          end
        end
      end
    end
  end
end
