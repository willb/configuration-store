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
          added_deps = fake_set_from_list(param_names.sort_by{ rand }.slice(0..5))
          
          param.ModifyDepends("ADD", added_deps, {})
          deps = param.GetDepends
          
          deps.should_have(added_deps.size).things
          added_deps.each {|dep| deps.should_include dep }
        end
      end
    end
  end
end
