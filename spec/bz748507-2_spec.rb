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
          @cwd = File.dirname(__FILE__)
          FileUtils.cp("#{@cwd}/bz748507-snap.db", "#{@cwd}/ohsnap.db")
          setup_rhubarb(:snapdb=>"#{@cwd}/ohsnap.db")
          @old_env = ENV["WALLABY_FIX_BROKEN_CONFIGS"]
          ENV["WALLABY_FIX_BROKEN_CONFIGS"] = "true"
          @store = Store.new
          reconstitute_db
        end
        
        after(:each) do
          FileUtils.rm("#{@cwd}/ohsnap.db")
          ENV["WALLABY_FIX_BROKEN_CONFIGS"] = @old_env
          @old_env = nil
          @cwd = nil
          teardown_rhubarb
        end
        
        include BaseDBFixture
        
        it "should adequately work around value-append markers in frozen configurations" do
          node = @store.getNode("willb-laptop")
          node.getConfig("version"=>1327695029622659)['DAEMON_LIST'].should_not match /^>=/
        end
      end
    end
  end
end
