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
        
        [true, false, :get_after].each do |should_activate|
          [true, false].each do |fix_broken|
            it "should not have value-append markers in frozen configurations when #{should_activate ? "activating" : "not activating"}#{should_activate == :get_after ? " before getting the affected node" : ""} when WALLABY_FIX_BROKEN_CONFIGS=#{fix_broken}" do
              old_fix=ConfigUtils.should_fix_broken_configs?
              ConfigUtils.should_fix_broken_configs=fix_broken
              
              begin
                Group.DEFAULT_GROUP.modifyFeatures("ADD", %w{Master NodeAccess}, {})
                Group.DEFAULT_GROUP.modifyParams("ADD", {'ALLOW_READ'=>'*', 'ALLOW_WRITE'=>'*', 'CONDOR_HOST'=>'localhost'}, {})
                
                node = @store.getNode("foo") unless should_activate == :get_after
                @store.activateConfiguration if should_activate
                node = @store.getNode("foo") if should_activate == :get_after
                
                (node.getConfig['DAEMON_LIST'] || "").should_not match /^>=/
                (node.getConfig("version"=>::Rhubarb::Util::timestamp)['DAEMON_LIST'] || "").should_not match /^>=/
              ensure
                ConfigUtils.should_fix_broken_configs=old_fix
              end
            end
          end
        end
      end
    end
  end
end
