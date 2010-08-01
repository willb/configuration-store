require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module Mrg
  module Grid
    module Config
      describe Feature do
        before(:each) do
          setup_rhubarb
          @store = Store.new
          @feature_names = %w{foo bar blah argh frotz}
        end

        after(:each) do
          $XXDEBUG = false
          teardown_rhubarb
        end
        

        {"includes"=>:modifyIncludedFeatures, "depends on"=>:modifyDepends}.each do |what, how|
          it "should not allow changing the store so that a feature immediately #{what} a feature that it already immediately conflicts with" do
            features = @feature_names.map {|fn| @store.addFeature(fn)}
            features[0].modifyConflicts("ADD", @feature_names.slice(1,4), {})
            
            @feature_names.slice(1,4).each do |conflicting_feature|
              lambda { features[0].send(how, "ADD", [conflicting_feature], {}) }.should raise_error(SPQR::ManageableObjectError)
            end
          end

          it "should not allow changing the store so that a feature immediately conflicts with a feature that it already immediately #{what}" do
            features = @feature_names.map {|fn| @store.addFeature(fn)}
            features[0].send(how, "ADD", @feature_names.slice(1,4), {})
            
            @feature_names.slice(1,4).each do |conflicting_feature|
              lambda { features[0].modifyConflicts("ADD", [conflicting_feature], {}) }.should raise_error(SPQR::ManageableObjectError)
            end
          end

          it "should not allow changing the store so that a feature immediately conflicts with a feature that it already transitively #{what}" do
            features = @feature_names.map {|fn| @store.addFeature(fn)}
            features[1].send(how, "ADD", @feature_names.slice(2,4), {})
            features[0].send(how, "ADD", @feature_names.slice(1,1), {})
            
            @feature_names.slice(2,4).each do |conflicting_feature|
              lambda { features[0].modifyConflicts("ADD", [conflicting_feature], {}) }.should raise_error(SPQR::ManageableObjectError)
            end
          end

          it "should not allow F to immediately #{what} on a feature that conflicts with it" do
            @feature_names.slice!(0,2)
            features = @feature_names.map {|fn| @store.addFeature(fn)}
            features[1].modifyConflicts("ADD", [@feature_names[0]], {})
            lambda {features[0].send(how, "ADD", [@feature_names[1]], {})}.should raise_error(SPQR::ManageableObjectError)
          end

          it "should not allow F to transitively #{what} on a feature that conflicts with it" do
            features = @feature_names.map {|fn| @store.addFeature(fn)}
            4.downto(1) do |x| 
              features[x].modifyConflicts("ADD", [@feature_names[0]], {})
              features[x].send(how, "ADD", [@feature_names[x+1]], {}) if @feature_names[x+1]
            end
            lambda {features[0].send(how, "ADD", [@feature_names[4]], {})}.should raise_error(SPQR::ManageableObjectError)
          end

          it "should not allow introducing new conflicts to a feature so as to break another feature that transitively #{what} it" do
            features = @feature_names.map {|fn| @store.addFeature(fn)}
            3.downto(0) {|x| features[x].send(how, "ADD", [@feature_names[x+1]], {})}
            lambda {
              new_conflicts = [@feature_names[0]]
              feature_to_change = features[4]
              feature_to_change.modifyConflicts("ADD", new_conflicts, {}) 
            }.should raise_error(SPQR::ManageableObjectError)
          end
        end
      end
    end
  end
end
