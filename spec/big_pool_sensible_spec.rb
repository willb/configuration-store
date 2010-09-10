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
          
          hlw = Group.find_first_by_name("HeavyLoadWorkers")
          hlw.membership.each do |n_name|
            node = Node.find_first_by_name(n_name)
            node.modifyMemberships("REMOVE", ["HeavyLoadWorkers"], {})
            node.modifyMemberships("ADD", ["hLoadWorkers"], {})
          end
          
          @hlw = Group.find_first_by_name("hLoadWorkers")
        end
        
        after(:each) do
          teardown_rhubarb
        end
        
        include BigPoolFixture
        
        it "should handle sensible changes to many nodes gracefully" do          
          hlw_with = @hlw.features | ["DisablePreemption"]
          hlw_without = @hlw.features - ["DisablePreemption"]
          first_set = second_set = []
          
          if @hlw.features.size == hlw_with.size
            first_set = hlw_without
            second_set = hlw_with
          else
            first_set = hlw_with
            second_set = hlw_without
          end
          
          @store.activateConfiguration
          
          1.times do |n|
            @hlw.modifyFeatures("REPLACE", first_set, {})
            @store.activateConfiguration
            
            @hlw.modifyFeatures("REPLACE", second_set, {})
            @store.activateConfiguration
          end
        end
      end
    end
  end
end