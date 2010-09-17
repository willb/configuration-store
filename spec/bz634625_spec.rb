require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'digest/md5'

module Mrg
  module Grid
    module Config

      describe Store do
        before(:each) do
          setup_rhubarb
          @store = Store.new

          @nodes = (0...5000).to_a.map {|nn| @store.addNode("eeny-meeny-miney-moe-catch-a-tiger-by-the-node-#{nn}")}
          @oil = @store.addParam("OIL")
          @water = @store.addParam("WATER")
          @oil.modifyConflicts("ADD", ["WATER"], {})
          @water.modifyConflicts("ADD", ["OIL"], {})
        end
        
        after(:each) do
          @nodes = nil
          teardown_rhubarb
        end
        
        it "should not return a too-large result from failing to activate a configuration" do
          Group.DEFAULT_GROUP.modifyParams("ADD", {"OIL"=>"olive", "WATER"=>"ice"}, {})
          results,warnings = @store.activateConfiguration
          
          results.should_not == {}
          results.keys.should_not include("*")
          warnings.should include("More validation errors may have occured; stopped processing nodes with #{5000 - results.keys.size} nodes left")
          "#{[results,warnings].inspect}".size.should_not > (QmfV1Kludges::MAX_ARG_SIZE)
        end
      end
    end
  end
end