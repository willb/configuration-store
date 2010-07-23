require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module Mrg
  module Grid
    module Config
      describe Feature do
        before(:each) do
          setup_rhubarb
          @store = Store.new
        end

        after(:each) do
          teardown_rhubarb
        end
        
      end
    end
  end
end
