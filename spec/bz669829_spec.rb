require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'digest/md5'

module Mrg
  module Grid
    module Config

      describe ConfigVersion do
        before(:each) do
          setup_rhubarb
          @store = Store.new
          reconstitute_db
        end
        
        after(:each) do
          teardown_rhubarb
        end
        
        include BaseDBFixture
        
        it "should not add spurious versioned configs when loading a new snapshot" do
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
          config_post = node.getConfig("version"=>nv+1)

          @store.loadSnapshot("pre")

          node = @store.getNode("foo")

          config_pre = node.getConfig("version"=>nv)

          config_pre["WALLABY_CONFIG_VERSION"].should == config_post["WALLABY_CONFIG_VERSION"]

          config_post.keys.sort.should == config_pre.keys.sort

          config_post.keys.each do |k|
            config_post[k].should == config_pre[k]
          end
        end
      end

      describe Node do
        before(:each) do
          setup_rhubarb
          @store = Store.new
        end
        
        after(:each) do
          teardown_rhubarb
        end
        
        def first_dbtext
          open("#{File.dirname(__FILE__)}/bz669829_first.yaml", "r") {|db| db.read}
        end
        
        def second_dbtext
          open("#{File.dirname(__FILE__)}/bz669829_second.yaml", "r") {|db| db.read}
        end
        
        include BaseDBFixture
        
        {"first->second"=>[:first_dbtext, :second_dbtext], "second->first"=>[:second_dbtext,:first_dbtext]}.each do |order,msgs|
        
          it "should not copy over versioned configs from +++DEFAULT upon snapshot load and activate (#{order})" do
            reconstitute_db(self.send(msgs[0]))
            Group.DEFAULT_GROUP.modifyParams("REPLACE", Group.DEFAULT_GROUP.params, {})

            @store.activateConfiguration

            first_versions = Hash[*Node.find_all.inject([]) {|acc,n| acc << n.name; acc << n.last_updated_version}]

            reconstitute_db(self.send(msgs[1]))

            @store.activateConfiguration

            second_versions = Hash[*Node.find_all.inject([]) {|acc,n| acc << n.name; acc << n.last_updated_version}]

            Node.find_all.each do |n|
              fv = first_versions[n.name]
              sv = second_versions[n.name]

              # if the configuration changed at all for this node
              if fv && sv
                old_config = n.getConfig("version"=>fv)
                new_config = n.getConfig("version"=>sv)

                if old_config["DAEMON_LIST"] != new_config["DAEMON_LIST"]
                  params, restart, reconfig = n.whatChanged(fv,sv)
                  params.should include("DAEMON_LIST")
                  restart.should include("master")
                end

              end
            end
          end
        end

        
      end
    end
  end
end