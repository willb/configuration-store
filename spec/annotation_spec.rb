require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'digest/md5'

module Mrg
  module Grid
    module Config
      {Feature=>:addFeature, Group=>:addExplicitGroup, Parameter=>:addParam, Snapshot=>:makeSnapshot, Subsystem=>:addSubsys}.each do |klass, makemsg|
        describe klass do
          before(:each) do
            setup_rhubarb
            @store = Store.new
            reconstitute_db
          end
        
          after(:each) do
            teardown_rhubarb
          end
        
          include BaseDBFixture
        
          it "should install annotation accessors on #{klass} instances" do
            @store.send(makemsg, "FOO")
            object = klass.find_first_by_name("FOO")
            object.should respond_to(:annotation)
            object.should respond_to(:annotation=)
            object.should respond_to(:setAnnotation)
          end

          it "should support annotations on #{klass} instances" do
            @store.send(makemsg, "FOO")
            object = klass.find_first_by_name("FOO")
            object.setAnnotation("This is an example annotation.")
            
            object = klass.find_first_by_name("FOO")
            object.annotation.should == "This is an example annotation."
          end
        end
      end
    end
  end
end