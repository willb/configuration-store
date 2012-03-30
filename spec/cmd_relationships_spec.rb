require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'digest/md5'
require 'mrg/grid/config/shell'

module Mrg
  module Grid
    module Config

      describe Store do
        before(:each) do
          setup_rhubarb
          @store = Store.new
          @mapping = {:Node=>:Node, :Feature=>:Feature, :Param=>:Parameter, :Subsys=>:Subsystem, :Group=>:Group}
        end
        
        after(:each) do
          teardown_rhubarb
        end
        

        [:Param, :Feature, :Subsys, :Group, :Node].each do |type|
          it "should replace relationships on #{type} with empty set if no list provided" do
            [:Param, :Feature, :Group, :Node].each do |f|
              m = Mrg::Grid::MethodUtils.find_store_method("add\\w*#{f}")
              @store.send(m, "test1")
              @store.send(m, "test2")
            end
            m = Mrg::Grid::MethodUtils.find_store_method("add\\w*#{type}")
            ent_name = "#{type}Test"
            ent = @store.send(m, ent_name)
            klass = @mapping[type]
            Mrg::Grid::MethodUtils.find_method("modify", klass).each do |f|
              getter = f.gsub(/modify/, '').downcase
              getter = "included_features" if getter.include?("includedfeature")
              items = nil
              if (type == :Feature || type == :Group) && f.include?("Param")
                items = {"test1"=>"", "test2"=>""}
              else
                items = ["test1", "test2"]
              end
              ent.send(f, "ADD", items, {})
              cmd = Mrg::Grid::Config::Shell.constants.grep(/^Replace#{type}#{getter.split('_')[0].gsub(/[ds]$/, '').capitalize}/)[0].to_sym
              Mrg::Grid::Config::Shell.const_get(cmd).new(@store, "").main([ent_name])
              ent.send(getter).empty?.should == true
            end
          end
        end

      end
    end
  end
end
