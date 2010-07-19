require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module Mrg
  module Grid
    module Config
      class ValidateStub
      end
      
      describe ValidateStub do
        include ConfigValidating

        before(:each) do
          setup_rhubarb
          @store = Store.new
          @pony_feature_names = %w{HighAvailabilityStable OatProvisioning PonyAccelerator AppleStorage}
          @anti_pony_feature_names = %w{GoatGetter GlueFactory}
          @pony_features = @pony_feature_names.map {|fn| @store.addFeature(fn)}
          @anti_pony_features = @anti_pony_feature_names.map {|fn| @store.addFeature(fn)}
          
          @pony_features.each {|f| f.modifyConflicts("ADD", @anti_pony_feature_names, {})}
          @anti_pony_features.each {|f| f.modifyConflicts("ADD", @pony_feature_names, {})}
        end

        after(:each) do
          teardown_rhubarb
        end

        it "should not identify spurious conflicts" do
          identify_conflicts(@pony_features).should == []
          identify_conflicts(@anti_pony_features).should == []
        end
        
        [1,2,3,4].each do |sz|
          it "should identify appropriate bidirectional conflicts induced by #{sz} problematic parameter(s)" do
            conflicts = identify_conflicts(@pony_features.slice(0,sz) + @anti_pony_features)
            conflicts.size.should == @anti_pony_features.size * sz
          end

          it "should identify appropriate unidirectional conflicts induced by #{sz} problematic source parameter(s)" do
            @anti_pony_features.each {|f| f.modifyConflicts("REPLACE", [], {})}
            conflicts = identify_conflicts(@pony_features.slice(0,sz) + @anti_pony_features)
            conflicts.size.should == @anti_pony_features.size * sz
          end

          it "should identify appropriate unidirectional conflicts induced by #{sz} problematic destination parameter(s)" do
            @pony_features.each {|f| f.modifyConflicts("REPLACE", [], {})}
            conflicts = identify_conflicts(@pony_features.slice(0,sz) + @anti_pony_features)
            conflicts.size.should == @anti_pony_features.size * sz
          end
        end
      end
    end
  end
end
