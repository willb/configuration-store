require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module Mrg
  module Grid
    module Config
      describe Parameter do
        before(:each) do
          setup_rhubarb
          @store = Store.new
          @add_msg = :addParam
          @find_msg = :getParam
          @gskey = "BIOTECH"
        end
        
        after(:each) do
          teardown_rhubarb
        end
        
        include DescribeGetterAndSetter

        it "enables creating a parameter" do
          param = @store.addParam("BIOTECH")
          param.name.should == "BIOTECH"
        end

        it "disallows creating a parameter with a name already in use" do
          param = @store.addParam("BIOTECH")
          lambda { @store.addParam("BIOTECH") }.should raise_error
        end


        it "enables finding a created parameter" do
          param = @store.addParam("BIOTECH")
          param = @store.getParam("BIOTECH")
          
          param.name.should == "BIOTECH"
        end
        
        it "should be possible to delete a parameter" do
          param = @store.addParam("BIOTECH")
          @store.removeParam("BIOTECH")
          
          lambda {@store.getParam("BIOTECH")}.should raise_error
        end

        it "should delete all traces of a deleted parameter" do
          OLD_DEFAULT = "The quick brown fox jumps over the lazy dad"
          OLD_TYPE = "timestamp"
          
          param = @store.addParam("BIOTECH")
          old_id = param.row_id
          param.setDefault(OLD_DEFAULT)
          param.setType(OLD_TYPE)
          @store.removeParam("BIOTECH")
          
          param = @store.addParam("BIOTECH")
          param = @store.getParam("BIOTECH")
          param.should_not == nil
          param.getDefault.should_not == OLD_DEFAULT
          param.getType.should_not == OLD_TYPE
          # param.row_id.should_not == old_id
        end

        
        it "enables setting a parameter's type" do
          describe_getter_and_setter(:setType, :getType, ["int", "string", "timestamp", "hostname"])
        end
        
        it "enables setting a parameter's default value" do
          describe_getter_and_setter(:setDefault, :getDefault, ("The quick brown fox jumps over the lazy dad".."The quick brown fox jumps over the lazy dog"))
        end
        
        it "enables setting a parameter's description" do
          vals = ["Does anyone know what this does?", "Perhaps not.", "All right, then."]
          describe_getter_and_setter(:setDescription, :getDescription, vals)
        end
        
        it "enables setting a parameter's visibility level" do
          describe_getter_and_setter(:setVisibilityLevel, :getVisibilityLevel, (0..12))
        end

        it "enables setting a parameter's requires-restart property" do
          describe_getter_and_setter(:setRequiresRestart, :getRequiresRestart, [true, false])
        end

        it "has no dependencies or conflicts by default" do
          param = @store.addParam("BIOTECH")
          param.getDepends.should == []
          param.getConflicts.should == []
        end
        
        it "accepts added dependencies" do
          param_names = ["BIOTECH"] + ("XAA".."XBZ").to_a
          params = param_names.inject({}) {|acc,p| acc[p] = @store.addParam(p) ; acc}
          
          param = params[param_names.shift]
          added_deps = param_names.sort_by{ rand }.slice(0..5)
          
          param.modifyDepends("ADD", added_deps, {})
          deps = param.getDepends
          
          deps.size.should == added_deps.size
          added_deps.each {|dep| deps.should include(dep) }
        end
        
        it "rejects dependency cycles" do
          param_names = ["BIOTECH"] + ("XAA".."XBZ").to_a
          params = param_names.map {|p| @store.addParam(p) }
          
          params.each_cons(2) do |source, dest|
            source.modifyDepends("ADD", [dest.name], {})
            deps = source.getDepends
            deps.size.should == 1
            deps.should include(dest.name)
          end
          
          lambda { params[-1].modifyDepends("ADD", params[0].name, {}) }.should raise_error

        end

        it "should not identify any parameters as applied to a node by default" do
          node = @store.addNode("frotz")
          Parameter.s_for_node(node).size.should == 0
        end

        it "should not identify any parameter dependencies as applied to a node by default" do
          node = @store.addNode("frotz")
          Parameter.dependencies_for_node(node).size.should == 0
        end

        it "should detect when parameters are added to a node's identity group" do
          param_names = ["BIOTECH"] + ("XAA".."XBZ").to_a
          params = param_names.map {|p| @store.addParam(p) }
          
          node = @store.addNode("frotz")
          
          node.idgroup.modifyParams("ADD", Hash[*param_names.map{|p| [p, p.downcase]}.flatten])
          
          pfn = Parameter.s_for_node(node)
          
          pfn.size.should == param_names.size
          
          param_names.each do |prm|
            pfn.should include(prm)
          end
        end

        it "should detect when parameters are added to the default group" do
          param_names = ["BIOTECH"] + ("XAA".."XDZ").to_a
          params = param_names.map {|p| @store.addParam(p) }
          
          params_to_add = param_names.sort_by { rand }.slice(0,15)
          
          node = @store.addNode("frotz")
          
          Group.DEFAULT_GROUP.modifyParams("ADD", Hash[*params_to_add.map{|p| [p, p.downcase]}.flatten])
          
          pfn = Parameter.s_for_node(node)
          
          pfn.size.should == params_to_add.size
          
          params_to_add.each do |prm|
            pfn.should include(prm)
          end
        end

        it "should detect when parameters are added to an explicit group" do
          param_names = ["BIOTECH"] + ("XAA".."XBZ").to_a
          params = param_names.map {|p| @store.addParam(p) }
          
          node = @store.addNode("frotz")
          group = @store.addExplicitGroup("argh")
          
          group.modifyParams("ADD", Hash[*param_names.map{|p| [p, p.downcase]}.flatten])

          pfn = Parameter.s_for_node(node)
          pfn.size.should == 0
          
          node.modifyMemberships("ADD", [group.name])
          
          pfn = Parameter.s_for_node(node)
          
          pfn.size.should == param_names.size
          
          param_names.each do |prm|
            pfn.should include(prm)
          end
        end
        
        it "should detect when parameters are added to a feature" do
          param_names = ["BIOTECH"] + ("XAA".."XBZ").to_a
          params = param_names.map {|p| @store.addParam(p) }
          
          node = @store.addNode("frotz")
          feature = @store.addFeature("Pony Accelerator")
          
          feature.modifyParams("ADD", Hash[*param_names.map{|p| [p, p.downcase]}.flatten])

          pfn = Parameter.s_for_node(node)
          pfn.size.should == 0
          
          node.idgroup.modifyFeatures("ADD", [feature.name])
          
          pfn = Parameter.s_for_node(node)
          
          pfn.size.should == param_names.size
          
          param_names.each do |prm|
            pfn.should include(prm)
          end
        end

        it "should detect when parameters are added to a feature included by another feature" do
          param_names = ["BIOTECH"] + ("XAA".."XBZ").to_a
          params = param_names.map {|p| @store.addParam(p) }
          
          node = @store.addNode("frotz")
          feature = @store.addFeature("Pony")
          feature1 = @store.addFeature("Pony Accelerator")
          
          feature1.modifyParams("ADD", Hash[*param_names.map{|p| [p, p.downcase]}.flatten])

          feature.modifyFeatures("ADD", [feature1.name])

          pfn = Parameter.s_for_node(node)
          pfn.size.should == 0
          
          node.idgroup.modifyFeatures("ADD", [feature.name])
          
          pfn = Parameter.s_for_node(node)
          
          pfn.size.should == param_names.size
          
          param_names.each do |prm|
            pfn.should include(prm)
          end
        end

        it "should identify immediate parameter dependencies for a node" do
          param_names = ["BIOTECH"] + ("XAA".."XBZ").to_a
          params = param_names.map {|p| @store.addParam(p) }
          
          dep_param_names = ("YAA".."YAF").to_a
          dep_params = dep_param_names.map {|p| @store.addParam(p) }
          
          params[0].modifyDepends("ADD", dep_param_names, {})
          
          node = @store.addNode("frotz")
          
          node.idgroup.modifyParams("ADD", Hash[*param_names.map{|p| [p, p.downcase]}.flatten])
          
          pfn = Parameter.s_for_node(node)
          pfn.size.should == param_names.size
          
          param_names.each do |prm|
            pfn.should include(prm)
          end

          dfn = Parameter.dependencies_for_node(node)
          dfn.size.should == dep_param_names.size
          
          dep_param_names.each do |dprm|
            dfn.should include(dprm)
          end
        end

        it "should identify transitive parameter dependencies for a node" do
          pending
        end

      
        it "adds dependencies idempotently" do
          param_names = ["BIOTECH"] + ("XAA".."XBZ").to_a
          params = param_names.inject({}) {|acc,p| acc[p] = @store.addParam(p) ; acc}
          
          param = params[param_names.shift]
          added_deps = param_names.sort_by{ rand }.slice(0..5)
          
          param.modifyDepends("ADD", added_deps, {})
          deps = param.getDepends
          
          pre_size = deps.size
          
          param.modifyDepends("ADD", added_deps, {})
          deps = param.getDepends
          
          deps.size.should == pre_size
        end

        it "does not remove preexisting dependencies when adding new ones" do
          param_names = ["BIOTECH"] + ("XAA".."XBZ").to_a
          params = param_names.inject({}) {|acc,p| acc[p] = @store.addParam(p) ; acc}
          
          param = params[param_names.shift]
          first_added = params[param_names.shift].name

          first_added_dep = [first_added]
          added_deps = param_names.sort_by{ rand }.slice(0..5)
          
          param.modifyDepends("ADD", first_added_dep, {})
          deps = param.getDepends
          
          pre_size = deps.size
          
          param.modifyDepends("ADD", added_deps, {})
          deps = param.getDepends
          
          deps.size.should == pre_size + added_deps.size
          
          added_deps.each {|dep| deps.should include(dep) }
          deps.should include(first_added)
        end

        it "does not allow params to introduce a dependency on themselves" do
          param = @store.addParam("BIOTECH")
          ["ADD", "REPLACE"].each do |cmd|
            lambda { param.modifyDepends(cmd, ["BIOTECH"], {}) }.should raise_error
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
          params = param_names.inject({}) {|acc,p| acc[p] = @store.addParam(p) ; acc}

          param = params[param_names.shift]
          added_cnfs = param_names.sort_by{ rand }.slice(0..5)

          param.modifyConflicts("ADD", added_cnfs, {})
          cnfs = param.getConflicts

          cnfs.size.should == added_cnfs.size
          added_cnfs.each {|dep| cnfs.should include(dep) }
        end

        it "adds conflicts idempotently" do
          param_names = ["BIOTECH"] + ("XAA".."XBZ").to_a
          params = param_names.inject({}) {|acc,p| acc[p] = @store.addParam(p) ; acc}

          param = params[param_names.shift]
          added_cnfs = param_names.sort_by{ rand }.slice(0..5)

          param.modifyConflicts("ADD", added_cnfs, {})
          cnfs = param.getConflicts

          pre_size = cnfs.size

          param.modifyConflicts("ADD", added_cnfs, {})
          cnfs = param.getConflicts

          cnfs.size.should == pre_size
        end

        it "does not remove preexisting conflicts when adding new ones" do
          param_names = ["BIOTECH"] + ("XAA".."XBZ").to_a
          params = param_names.inject({}) {|acc,p| acc[p] = @store.addParam(p) ; acc}

          param = params[param_names.shift]
          first_added = params[param_names.shift].name

          first_added_dep = [first_added]
          added_cnfs = param_names.sort_by{ rand }.slice(0..5)

          param.modifyConflicts("ADD", first_added_dep, {})
          cnfs = param.getConflicts

          pre_size = cnfs.size

          param.modifyConflicts("ADD", added_cnfs, {})
          cnfs = param.getConflicts

          cnfs.size.should == pre_size + added_cnfs.size

          added_cnfs.each {|dep| cnfs.should include(dep) }
          cnfs.should include(first_added)
        end

        it "does not allow params to introduce a conflict with themselves" do
          param = @store.addParam("BIOTECH")
          ["ADD", "REPLACE"].each do |cmd|
            lambda { param.modifyConflicts(cmd, ["BIOTECH"], {}) }.should raise_error
          end
        end
        
        
      end
    end
  end
end
