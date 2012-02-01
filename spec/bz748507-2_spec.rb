require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'digest/md5'

module Mrg
  module Grid
    module Config
      class BZ748507; end

      describe BZ748507 do

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
          ENV["WALLABY_FIX_BROKEN_CONFIGS"] = @old_env
          @old_env = nil
          teardown_rhubarb
          FileUtils.rm("#{@cwd}/ohsnap.db")
          @cwd = nil
        end
        
        include BaseDBFixture
        
        it "should adequately work around value-append markers in frozen configurations" do
          pending "set WALLABY_TEST_APPEND_WORKAROUND to run these examples" unless ENV["WALLABY_TEST_APPEND_WORKAROUND"]
          node = @store.getNode("willb-laptop")
          node.getConfig("version"=>1327695029622659)['DAEMON_LIST'].should_not match /^>=/
        end
      end
    end
  end
end
