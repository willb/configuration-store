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
          teardown_rhubarb
        end
        

        {"includes"=>:modifyIncludedFeatures, "depends on"=>:modifyDepends}.each do |what, how|
          it "should not be possible to change the store so that a feature immediately #{what} a feature that it already immediately conflicts with" do
            features = @feature_names.map {|fn| @store.addFeature(fn)}
            features[0].modifyConflicts("ADD", @feature_names.slice(1,4), {})
            
            @feature_names.slice(1,4).each do |conflicting_feature|
              lambda { features[0].send(how, "ADD", [conflicting_feature], {}) }.should raise_error(SPQR::ManageableObjectError)
            end
          end

          it "should not be possible to change the store so that a feature immediately conflicts with a feature that it already immediately #{what}" do
            features = @feature_names.map {|fn| @store.addFeature(fn)}
            features[0].send(how, "ADD", @feature_names.slice(1,4), {})
            
            @feature_names.slice(1,4).each do |conflicting_feature|
              lambda { features[0].modifyConflicts("ADD", [conflicting_feature], {}) }.should raise_error(SPQR::ManageableObjectError)
            end
          end

          it "should not be possible to change the store so that a feature immediately conflicts with a feature that it already transitively #{what}" do
            features = @feature_names.map {|fn| @store.addFeature(fn)}
            features[1].send(how, "ADD", @feature_names.slice(2,4), {})
            features[0].send(how, "ADD", @feature_names.slice(1,1), {})
            
            @feature_names.slice(2,4).each do |conflicting_feature|
              lambda { features[0].modifyConflicts("ADD", [conflicting_feature], {}) }.should raise_error(SPQR::ManageableObjectError)
            end
          end

          it "should not be possible to introduce new conflicts to a feature so as to break another feature that transitively #{what} it" do
            features = @feature_names.map {|fn| @store.addFeature(fn)}
            3.downto(0) {|x| features[x].send(how, "ADD", [@feature_names[x+1]], {})}
            lambda { features[4].modifyConflicts("ADD", [@feature_names[0]], {}) }.should raise_error(SPQR::ManageableObjectError)
          end
        end
      end
    end
  end
end
