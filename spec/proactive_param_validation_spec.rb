require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module Mrg
  module Grid
    module Config
      describe Parameter do
        before(:each) do
          setup_rhubarb
          @store = Store.new
          @param_names = %w{BIOTECH MAX_JOBS_CRASHING UNDOCUMENTED_KNOB ARBITRARY_RANK_FUDGE_FACTOR LOSE_MY_DATA}
        end

        after(:each) do
          teardown_rhubarb
        end
        

        {"depends on"=>:modifyDepends}.each do |what, how|
          it "should not be possible to change the store so that a param immediately depends on a param that it already immediately conflicts with" do
            params = @param_names.map {|fn| @store.addParam(fn)}
            params[0].modifyConflicts("ADD", @param_names.slice(1,4), {})
            
            @param_names.slice(1,4).each do |conflicting_param|
              lambda { params[0].modifyDepends("ADD", [conflicting_param], {}) }.should raise_error(SPQR::ManageableObjectError)
            end
          end

          it "should not be possible to change the store so that a param immediately conflicts with a param that it already immediately depends on" do
            params = @param_names.map {|fn| @store.addParam(fn)}
            params[0].modifyDepends("ADD", @param_names.slice(1,4), {})
            
            @param_names.slice(1,4).each do |conflicting_param|
              lambda { params[0].modifyConflicts("ADD", [conflicting_param], {}) }.should raise_error(SPQR::ManageableObjectError)
            end
          end

          it "should not be possible to change the store so that a param immediately conflicts with a param that it already transitively depends on" do
            params = @param_names.map {|fn| @store.addParam(fn)}
            params[1].modifyDepends("ADD", @param_names.slice(2,4), {})
            params[0].modifyDepends("ADD", @param_names.slice(1,1), {})
            
            @param_names.slice(2,4).each do |conflicting_param|
              lambda { params[0].modifyConflicts("ADD", [conflicting_param], {}) }.should raise_error(SPQR::ManageableObjectError)
            end
          end

          it "should not be possible to introduce new conflicts to a param so as to break another param that transitively depends on it" do
            params = @param_names.map {|fn| @store.addParam(fn)}
            3.downto(0) {|x| params[x].modifyDepends("ADD", [@param_names[x+1]], {})}
            lambda { params[4].modifyConflicts("ADD", [@param_names[0]], {}) }.should raise_error(SPQR::ManageableObjectError)
          end
          
          it "should not be possible for P to immediately #{what} on a param that conflicts with it" do
            pending "FIXME:  need this test and code to make it pass"
          end

          it "should not be possible for P to transitively #{what} on a param that conflicts with it" do
            pending "FIXME:  need this test and code to make it pass"
          end

          
        end
      end
    end
  end
end
