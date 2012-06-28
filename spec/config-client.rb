require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'digest/md5'

module Mrg
  module Grid
    module Config

      describe Store do
        include BigPoolFixture

        before(:each) do
          setup_rhubarb
          @store = Store.new
          reconstitute_db(dbtext)
        end
        
        after(:each) do
          teardown_rhubarb
        end

        it "should return all must change parameters in the store" do
          mc = @store.getMustChangeParams
          mc.each_key do |name|
            p = @store.getParam(name)
            p.must_change.should == true
          end
          list = Parameter.find_by(:must_change=>true)
          list.each do |p|
            mc.keys.should include p.name
          end
          list.length.should == mc.length
        end

      end
    end
  end
end
