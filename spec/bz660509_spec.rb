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
        
        def dbtext
          open("#{File.dirname(__FILE__)}/incomplete_daemon_list.yaml", "r") {|db| db.read}
        end
        
        it "should correctly store versioned configurations so that the latest configuration is the same as the current configuration" do
          @store.activateConfiguration
          Node.find_all.each do |node|
            cnf = node.getConfig("version"=>node.last_updated_version)["DAEMON_LIST"]
            cnf.should_not == []
            cnf.should == node.getConfig["DAEMON_LIST"]
          end
        end
      end
    end
  end
end
