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
        
        def dbtext
          open("#{File.dirname(__FILE__)}/bz669829_first.yaml", "r") {|db| db.read}
        end
        
        def second_dbtext
          open("#{File.dirname(__FILE__)}/bz669829_second.yaml", "r") {|db| db.read}
        end
        
        include BaseDBFixture
        
        it "should restart the master when DAEMON_LIST changes after a snapshot load and activate" do
          @store.activateConfiguration
          
          first_versions = Hash[*Node.find_all.inject([]) {|acc,n| acc << n.name; acc << n.last_updated_version}]
          
          reconstitute_db(second_dbtext)
          
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