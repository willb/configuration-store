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
          
          @hlw = Group.find_first_by_name("hLoadWorkers")
          @torture_count = ((ENV['WALLABY_TORTURE_TEST_REPS'] || 1).to_i rescue 1)
          
        end
        
        after(:each) do
          teardown_rhubarb
        end
        
        include BigPoolFixture
        
        SENSIBLE_TIMEOUT = 60 * 5
        
        def dbtext
          open("#{File.dirname(__FILE__)}/big-pool-sensible.yaml", "r") {|db| db.read}
        end
        
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
          
          @torture_count.times do |n|
            [first_set, second_set].each do |fset|
              lambda do
                Timeout::timeout(SENSIBLE_TIMEOUT) do
                  @hlw.modifyFeatures("REPLACE", fset, {})
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