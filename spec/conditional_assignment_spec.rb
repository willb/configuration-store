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
        
        it "should handle some common cases involving conditional assignment" do
          node = @store.addNode("latebound.local.")
          prm = @store.addParam("LATEBOUND")
          group = @store.addExplicitGroup("gruppo")

          node.identity_group.modifyParams("ADD", {"LATEBOUND"=>"?=IDENTITY"}, {})
          @store.activateConfiguration
          
          node.getConfig["LATEBOUND"].should == "IDENTITY"
          
          @store.getDefaultGroup.modifyParams("ADD", {"LATEBOUND"=>"?=COND_DEFAULT"}, {})
          @store.activateConfiguration

          node.getConfig["LATEBOUND"].should == "COND_DEFAULT"

          walkin = @store.getNode("walkin.local.")
          walkin.getConfig["LATEBOUND"].should == "COND_DEFAULT"
          
          @store.getDefaultGroup.modifyParams("ADD", {"LATEBOUND"=>"DEFAULT"}, {})
          @store.activateConfiguration

          node.getConfig["LATEBOUND"].should == "DEFAULT"

          @store.getDefaultGroup.modifyParams("REMOVE", {"LATEBOUND"=>"DEFAULT"}, {})
          @store.activateConfiguration
          group.modifyParams("ADD", {"LATEBOUND"=>"?=GRUPPO"}, {})
          walkin.modifyMemberships("ADD", [group.name], {})

          node.getConfig["LATEBOUND"].should == "IDENTITY"

          walkin.getConfig["LATEBOUND"].should == "GRUPPO"
        end

        it "should handle conditional assignment sensibly in features" do
          pending "this example requires Array#permutation, which your ruby doesn't support; sorry!" unless [].respond_to?(:permutation)
          @store.addParam("LATEBOUND")
          features = %{alpha beta gamma}.map {|f| result = @store.addFeature(f) ; result.modifyParams("ADD", {"LATEBOUND"=>"?=#{f.upcase}"}, {}); result}
          
          features.map {|f| f.name}.permutation.each do |flist|
            node = @store.getNode("example.local.")
            node.identity_group.modifyFeatures("REPLACE", flist, {})
            @store.activateConfiguration
            node.getConfig["LATEBOUND"].should == flist[-1].upcase
          end
        end
      end
    end
  end
end
