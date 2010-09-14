require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'digest/md5'

module Mrg
  module Grid
    module Config

      describe Node do
        before(:each) do
          setup_rhubarb
          @store = Store.new
          @torture_count = ((ENV['WALLABY_TORTURE_TEST_REPS'] || 1).to_i rescue 1)
        end
        
        after(:each) do
          teardown_rhubarb
        end
        
        include BigPoolFixture
        
        TORTURE_TIMEOUT = 60 * 10
        
        it "should handle large changes gracefully" do
          reconstitute_db
          pending "You've set WALLABY_STOP_MARSUPIAL_ABUSE; the big torture test is disabled" if ENV['WALLABY_STOP_MARSUPIAL_ABUSE']
          
          hlw = Group.find_first_by_name("HeavyLoadWorkers")
          
          hlw_with = hlw.features | ["DisablePreemption"]
          hlw_without = hlw.features - ["DisablePreemption"]
          first_set = second_set = []
          
          if hlw.features.size == hlw_with.size
            first_set = hlw_without
            second_set = hlw_with
          else
            first_set = hlw_with
            second_set = hlw_without
          end
          
          @torture_count.times do |n|
            [first_set, second_set].each do |fset|
              lambda do
                Timeout::timeout(TORTURE_TIMEOUT) do
                  hlw.modifyFeatures("REPLACE", fset, {})
                  @store.activateConfiguration
                end
              end.should_not raise_error
            end            
          end
        end
      end
    end
  end
end