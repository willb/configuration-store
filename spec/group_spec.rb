require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module Mrg
  module Grid
    module Config
      describe Group do
        before(:each) do
          setup_rhubarb
          @store = Store.new
          @add_msg = :addExplicitGroup
          @find_msg = :getGroupByName
          @gskey = "PONY_GROUP"
        end

        after(:each) do
          teardown_rhubarb
        end

        include DescribeGetterAndSetter
        
        it "should not be possible to rename the default group" do
          lambda {Group.DEFAULT_GROUP.setName("foo!")}.should raise_error
        end

        it "should not be possible to remove the default group" do
          lambda {@store.removeGroup(Group.DEFAULT_GROUP.name)}.should raise_error
        end
        
        it "should have an appropriate display name when it is the default group" do
          Group.DEFAULT_GROUP.display_name.should == "the default group"
        end

        it "should have an appropriate display name when it is an identity group" do
          %w{frotz blotz knotz argh blargh}.each do |nn|
            node = @store.addNode(nn)
            node.idgroup.display_name.should == "the identity group for #{node.name}"
          end
        end

        it "should have an appropriate display name when it is an explicit group" do
          %w{foo bar blah argh}.each do |gn|
            group = @store.addExplicitGroup(gn)
            group.display_name.should == "group #{group.name}"
          end
        end

        
        it "should be instantiable" do
          thing = @store.send(@add_msg, @gskey)
          thing.should_not == nil
          @store.send(@find_msg, @gskey).row_id.should == thing.row_id
        end

        it "should disallow creating two groups with the same name" do
          thing = @store.send(@add_msg, @gskey)
          lambda { thing2 = @store.send(@add_msg, @gskey) }.should raise_error
        end

        it "should no longer exist after it is deleted" do
          thing = @store.send(@add_msg, @gskey)
          @store.removeGroup(@gskey)
          
          lambda { @store.send(@find_msg, @gskey) }.should raise_error
          lambda { @store.removeGroup(@gskey) }.should raise_error
        end
        
        
        it "should not be possible to set a group's name to a taken name" do
          group = @store.send(@add_msg, @gskey)
          group2 = @store.send(@add_msg, @gskey.reverse)
          
          lambda { group2.setName(@gskey) }.should raise_error
        end
        
        [[%w{HighAvailabilityStable OatAccelerator}, ["ADD", %w{AppleManager}, {}], %w{HighAvailabilityStable OatAccelerator AppleManager}, "at the lowest priority"],
        [%w{HighAvailabilityStable OatAccelerator}, ["ADD", %w{AppleManager AppleManager}, {}], %w{HighAvailabilityStable OatAccelerator AppleManager}, "idempotently with respect to argument duplication"],
        [%w{HighAvailabilityStable OatAccelerator AppleManager}, ["ADD", %w{AppleManager}, {}], %w{HighAvailabilityStable OatAccelerator AppleManager}, "idempotently with respect to feature membership duplication"],
        [%w{AppleManager HighAvailabilityStable OatAccelerator}, ["ADD", %w{AppleManager}, {}], %w{AppleManager HighAvailabilityStable OatAccelerator}, "idempotently with respect to ordering"]].each do |f_before, args, f_after, desc|
        
          it "should add features #{desc}" do
            group = @store.send(@add_msg, @gskey)
            (f_before | f_after).each {|feature| @store.addFeature(feature)}
            group.modifyFeatures("REPLACE", f_before, {})
            group.features.should == f_before
            group.modifyFeatures(*args)
            group.features.should == f_after
          end
        end
        
      end
    end
  end
end
