require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module Mrg
  module Grid
    module Config

      describe Node do
        before(:each) do
          # set up db
        end
        
        it "should have an accessible name" do
          n = Node.new
          n.should respond_to(:name)
        end

        it "should have a modifiable name" do
          n = Node.new
          n.should respond_to(:name=)
        end

        it "should update the name when the name is set" do
          n = Node.new
          bogus_name = ""
          9.times { bogus_name << ((rand*26).floor + ?a).chr }
          n.name = bogus_name
          n.name.should == bogus_name
        end

        it "should have a way to access the pool value" do
          n = Node.new
          n.should respond_to(:GetPool)
        end

        it "should have a way to modify the pool value" do
          n = Node.new
          n.should respond_to(:SetPool)
        end

        
      end

    end
  end
end
