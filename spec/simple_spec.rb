require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'digest/md5'

module Mrg
  module Grid
    module Config

      describe Node do
        before(:each) do
          setup_rhubarb
          @store = Store.new
          @mapping = {"Node"=>Node, "Feature"=>Feature, "Param"=>Parameter, "Subsys"=>Subsystem}
        end
        
        after(:each) do
          teardown_rhubarb
        end
        

        ["Node", "Feature", "Param", "Subsys"].each do |ent|
          it "should create #{ent.downcase}" do
            name = "example-#{ent.downcase}"
            thing = @store.send("add#{ent}", name)
            thing.should_not == nil
            thing2 = @store.send("get#{ent}", name)
            thing2.should_not == nil
            thing2.name.should == thing.name
          end
          
          it "should be able to find #{ent.downcase}s" do
            name = "example-#{ent.downcase}"
            thing = @store.send("add#{ent}", name)

            klass = @mapping[ent]
            
            thing2 = klass.find_first_by_name(name)
            thing2.name.should == name
          end
        end

      end
    end
  end
end
