require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'digest/md5'

module Mrg
  module Grid
    module Config

      describe Node do

        def dbtext
          open("/var/lib/condor-wallaby-base-db/condor-base-db.snapshot", "r") {|db| db.read}
        end

        before(:each) do
          setup_rhubarb
          @store = Store.new
          reconstitute_db
        end
        
        after(:each) do
          teardown_rhubarb
        end
        
        include BaseDBFixture
        
        it "should not have value-append markers in frozen configurations" do
          node = @store.getNode("foo")
          Group.DEFAULT_GROUP.modifyFeatures("ADD", %w{Master NodeAccess}, {})
          Group.DEFAULT_GROUP.modifyParams("ADD", {'ALLOW_READ'=>'*', 'ALLOW_WRITE'=>'*', 'CONDOR_HOST'=>'localhost'}, {})
          @store.activateConfiguration

          node.getConfig("version"=>::Rhubarb::Util::timestamp)['DAEMON_LIST'].should_not match /^>=/
        end
      end
    end
  end
end
