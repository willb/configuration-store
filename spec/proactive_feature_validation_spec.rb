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
          
          it "should not allow F to immediately #{what} on a feature whose param set conflicts with that of F" do
            @feature_names.slice!(0,2)
            features = @feature_names.map {|fn| @store.addFeature(fn)}
            param_names = %w{FOO BAR}
            params = param_names.map {|pn| @store.addParam(pn)}
            
            puts "MODIFYING CONFLICTS FOR PARAM #{param_names[0]}...before is #{params[0].conflicts.inspect}" if $XXDEBUG
            params[0].modifyConflicts("ADD", [param_names[1]], {})
            puts "DONE MODIFYING CONFLICTS FOR PARAM #{param_names[0]}...after is #{params[0].conflicts.inspect}" if $XXDEBUG
            puts "MODIFYING CONFLICTS FOR PARAM #{param_names[1]}...before is #{params[1].conflicts.inspect}" if $XXDEBUG
            params[1].modifyConflicts("ADD", [param_names[0]], {})
            puts "DONE MODIFYING CONFLICTS FOR PARAM #{param_names[1]}...after is #{params[1].conflicts.inspect}" if $XXDEBUG
            
            [0,1].each do |x|
              puts "MODIFYING PARAMS FOR FEATURE #{@feature_names[x]}...before is #{features[x].params.inspect}" if $XXDEBUG
              features[x].modifyParams("ADD", {param_names[x]=>"example value #{x}"}, {})
              puts "DONE MODIFYING PARAMS FOR FEATURE #{@feature_names[x]}...after is #{features[x].params.inspect}" if $XXDEBUG
            end
            
            lambda {
              puts "=====HERE'S THE GOOD PART=====" if $XXDEBUG
              puts "sending #{how} to #{@feature_names[0]} with arg #{[@feature_names[1]].inspect}" if $XXDEBUG
              features[0].send(how, "ADD", [@feature_names[1]], {})
            }.should raise_error(SPQR::ManageableObjectError)
          end
        end
      end
    end
  end
end
