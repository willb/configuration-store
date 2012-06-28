require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'digest/md5'
require 'mrg/grid/config/shell'

module Mrg
  module Grid
    module Config

      describe Store do
        before(:each) do
          setup_rhubarb
          @store = Store.new
        end
        
        after(:each) do
          teardown_rhubarb
        end
        

        it "should remove snapshots" do
          @store.makeSnapshot("test")
          Snapshot.count.should == 1
          Mrg::Grid::Config::Shell::RemoveSnapshot.new(@store, "").main(["test"])
          Snapshot.count.should == 0
        end

      end
    end
  end
end
