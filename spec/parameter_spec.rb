require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module Mrg
  module Grid
    module Config
      describe Parameter do
        before(:each) do
          setup_rhubarb
          @store = Store.new
          @add_msg = :AddParam
          @find_msg = :GetParam
          @gskey = "BIOTECH"
        end
        
        after(:each) do
          teardown_rhubarb
        end
        
        include DescribeGetterAndSetter

        it "enables creating a parameter" do
          param = @store.AddParam("BIOTECH")
          param.name.should == "BIOTECH"
        end

        it "enables finding a created parameter" do
          param = @store.AddParam("BIOTECH")
          param = @store.GetParam("BIOTECH")
          
          param.name.should == "BIOTECH"
        end
        
        it "should be possible to delete a parameter" do
          param = @store.AddParam("BIOTECH")
          @store.RemoveParam("BIOTECH")
          
          @store.GetParam("BIOTECH").should == nil
        end

        it "should delete all traces of a deleted parameter" do
          OLD_DEFAULT = "The quick brown fox jumps over the lazy dad"
          OLD_TYPE = "timestamp"
          
          param = @store.AddParam("BIOTECH")
          old_id = param.row_id
          param.SetDefault(OLD_DEFAULT)
          param.SetType(OLD_TYPE)
          @store.RemoveParam("BIOTECH")
          
          param = @store.AddParam("BIOTECH")
          param = @store.GetParam("BIOTECH")
          param.should_not == nil
          param.GetDefault.should_not == OLD_DEFAULT
          param.GetType.should_not == OLD_TYPE
          # param.row_id.should_not == old_id
        end

        
        it "enables setting a parameter's type" do
          describe_getter_and_setter(:SetType, :GetType, ["int", "string", "timestamp", "hostname"])
        end
        
        it "enables setting a parameter's default value" do
          describe_getter_and_setter(:SetDefault, :GetDefault, ("The quick brown fox jumps over the lazy dad".."The quick brown fox jumps over the lazy dog"))
        end
        
        it "enables setting a parameter's description" do
          vals = ["Does anyone know what this does?", "Perhaps not.", "All right, then."]
          describe_getter_and_setter(:SetDescription, :GetDescription, vals)
        end
        
        it "enables setting a parameter's visibility level" do
          describe_getter_and_setter(:SetVisibilityLevel, :GetVisibilityLevel, (0..12))
        end

        it "enables setting a parameter's requires-restart property" do
          describe_getter_and_setter(:SetRequiresRestart, :GetRequiresRestart, [true, false])
        end

        it "has no dependencies or conflicts by default" do
          param = @store.AddParam("BIOTECH")
          param.GetDepends.should == {}
          param.GetConflicts.should == {}
        end
        
        it "accepts added dependencies" do
          param_names = ["BIOTECH"] + ("XAA".."XBZ").to_a
          params = param_names.inject({}) {|acc,p| acc[p] = @store.AddParam(p) ; acc}
          
          param = params[param_names.shift]
          added_deps = FakeSet[*param_names.sort_by{ rand }.slice(0..5)]
          
          param.ModifyDepends("ADD", added_deps, {})
          deps = param.GetDepends
          
          deps.keys.size.should == added_deps.size
          added_deps.keys.each {|dep| deps.keys.should include(dep) }
        end

        it "adds dependencies idempotently" do
          param_names = ["BIOTECH"] + ("XAA".."XBZ").to_a
          params = param_names.inject({}) {|acc,p| acc[p] = @store.AddParam(p) ; acc}
          
          param = params[param_names.shift]
          added_deps = FakeSet[*param_names.sort_by{ rand }.slice(0..5)]
          
          param.ModifyDepends("ADD", added_deps, {})
          deps = param.GetDepends
          
          pre_size = deps.keys.size
          
          param.ModifyDepends("ADD", added_deps, {})
          deps = param.GetDepends
          
          deps.keys.size.should == pre_size
        end

        it "does not remove preexisting dependencies when adding new ones" do
          param_names = ["BIOTECH"] + ("XAA".."XBZ").to_a
          params = param_names.inject({}) {|acc,p| acc[p] = @store.AddParam(p) ; acc}
          
          param = params[param_names.shift]
          first_added = params[param_names.shift].name

          first_added_dep = FakeSet[*[first_added]]
          added_deps = FakeSet[*param_names.sort_by{ rand }.slice(0..5)]
          
          param.ModifyDepends("ADD", first_added_dep, {})
          deps = param.GetDepends
          
          pre_size = deps.keys.size
          
          param.ModifyDepends("ADD", added_deps, {})
          deps = param.GetDepends
          
          deps.keys.size.should == pre_size + added_deps.size
          
          added_deps.keys.each {|dep| deps.keys.should include(dep) }
          deps.keys.should include(first_added)
        end

        it "does not allow params to introduce a dependency on themselves" do
          param = @store.AddParam("BIOTECH")
          ["ADD", "REPLACE"].each do |cmd|
            lambda { param.ModifyDepends(cmd, {"BIOTECH"=>true}, {}) }.should raise_error
          end
        end

        it "allows replacing the dependency set" do
          pending
        end
        
        it "allows replacing the conflict set" do
          pending
        end

        it "accepts added conflicts" do
          param_names = ["BIOTECH"] + ("XAA".."XBZ").to_a
          params = param_names.inject({}) {|acc,p| acc[p] = @store.AddParam(p) ; acc}

          param = params[param_names.shift]
          added_cnfs = FakeSet[*param_names.sort_by{ rand }.slice(0..5)]

          param.ModifyConflicts("ADD", added_cnfs, {})
          cnfs = param.GetConflicts

          cnfs.keys.size.should == added_cnfs.size
          added_cnfs.keys.each {|dep| cnfs.keys.should include(dep) }
        end

        it "adds conflicts idempotently" do
          param_names = ["BIOTECH"] + ("XAA".."XBZ").to_a
          params = param_names.inject({}) {|acc,p| acc[p] = @store.AddParam(p) ; acc}

          param = params[param_names.shift]
          added_cnfs = FakeSet[*param_names.sort_by{ rand }.slice(0..5)]

          param.ModifyConflicts("ADD", added_cnfs, {})
          cnfs = param.GetConflicts

          pre_size = cnfs.keys.size

          param.ModifyConflicts("ADD", added_cnfs, {})
          cnfs = param.GetConflicts

          cnfs.keys.size.should == pre_size
        end

        it "does not remove preexisting conflicts when adding new ones" do
          param_names = ["BIOTECH"] + ("XAA".."XBZ").to_a
          params = param_names.inject({}) {|acc,p| acc[p] = @store.AddParam(p) ; acc}

          param = params[param_names.shift]
          first_added = params[param_names.shift].name

          first_added_dep = FakeSet[*[first_added]]
          added_cnfs = FakeSet[*param_names.sort_by{ rand }.slice(0..5)]

          param.ModifyConflicts("ADD", first_added_dep, {})
          cnfs = param.GetConflicts

          pre_size = cnfs.keys.size

          param.ModifyConflicts("ADD", added_cnfs, {})
          cnfs = param.GetConflicts

          cnfs.keys.size.should == pre_size + added_cnfs.size

          added_cnfs.keys.each {|dep| cnfs.keys.should include(dep) }
          cnfs.keys.should include(first_added)
        end

        it "does not allow params to introduce a conflict with themselves" do
          param = @store.AddParam("BIOTECH")
          ["ADD", "REPLACE"].each do |cmd|
            lambda { param.ModifyConflicts(cmd, {"BIOTECH"=>true}, {}) }.should raise_error
          end
        end
        
        
      end
    end
  end
end
