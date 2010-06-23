$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rubygems' rescue nil

require 'rhubarb/rhubarb'
require 'mrg/grid/config'
require 'enumerator'

require 'spec'
require 'spec/autorun'

require 'mrg/grid/config-client'
require 'mrg/grid/config-proxies'


Spec::Runner.configure do |config|
  
end

include Mrg::Grid::Config

def setup_rhubarb(kwargs=nil)
  kwargs ||= {}
  dbname = kwargs[:dbname] || ":memory:"
  classes = kwargs[:classes] || (MAIN_DB_TABLES + SNAP_DB_TABLES)

  Rhubarb::Persistence::open(dbname, :default, false)
  classes.each {|cl| cl.create_table}
end

def teardown_rhubarb
  Rhubarb::Persistence::close
end

module DescribeGetterAndSetter
  def describe_getter_and_setter(setmsg, getmsg, values, key=nil)
    key ||= @gskey
    param = @store.send(@add_msg, key)
    
    values.each do |val|
      param = @store.send(@find_msg, key)
      param.send(setmsg, val)
      
      param = @store.send(@find_msg, key)
      param.send(getmsg).should == val
    end
  end
end

module BaseDBFixture
  def reconstitute_db
    @store.storeinit("resetdb"=>"yes")
    s = Mrg::Grid::SerializedConfigs::ConfigLoader.new(@store, dbtext)
    s.load
  end
  
  def dbtext
    open("#{File.dirname(__FILE__)}/base-db.yaml", "r") {|db| db.read}
  end

  # defaultable parameters that need restart and their affiliated subsystems
  def restart_params
    @restart_params ||= Parameter.find_by(:needsRestart=>true, :must_change=>false).inject({}) do |acc,p| 
      acc[p.name] = Subsystem.s_for_param(p).map {|ss| ss.name}
      acc
    end
  end
  
  # as above, except no restart
  def reconfig_params
    @reconfig_params ||= Parameter.find_by(:needsRestart=>false, :must_change=>false).inject({}) do |acc,p| 
      acc[p.name] = Subsystem.s_for_param(p).map {|ss| ss.name}
      acc
    end
  end
  
  def param_deps
    @param_deps ||= ParameterArc.find_by(:label=>ArcLabel.depends_on('param')).inject(Hash.new {|h,k| h[k] = [] ; h[k]}) do |acc,pa|
      acc[pa.source.name] << pa.dest.name
      acc
    end
  end
  
  def param_conflicts
    @param_conflicts ||= ParameterArc.find_by(:label=>ArcLabel.conflicts_with('param')).inject(Hash.new {|h,k| h[k] = [] ; h[k]}) do |acc,pa|
      acc[pa.source.name] << pa.dest.name
      acc
    end
  end
end

module SpecHelper
  module ClassMethods
    
  end
  
  module InstanceMethods
    
  end
  
  def self.included(receiver)
    receiver.extend         ClassMethods
    receiver.send :include, InstanceMethods
  end
end

module WhatChangedTester
  module Im
    def get_params(restart=false)
      (self.send(restart ? :restart_params : :reconfig_params).keys - param_deps.keys - param_conflicts.keys).sort_by {rand}
    end
  
    def get_values
      o = Object.new
      def o.shift
        @val = (@val && @val + 1) || 0
        "value_#{@val}"
      end
  
      o
    end
    
    def setup_whatchanged_tests
      reconstitute_db
    end
    
    def unify_param_expectations(c_before, c_after, expected_diff, restart_params=false)
      params = get_params(restart_params)
      values = get_values
      domains_and_keys = {:PARAM=>Hash.new {|h,k| h[k] = params.shift},
        :VALUE=>Hash.new {|h,k| h[k] = values.shift}}
      
      b = {}
      a = {}
  
      [[b, c_before], [a, c_after]].each do |hash, source|
        source.each do |k,v|
          key_domain = k[0]
          key_var = k[1]
          val_domain = v[0]
          val_var = v[1]
  
          hash[domains_and_keys[key_domain][key_var]] = domains_and_keys[val_domain][val_var]
        end
      end
      
      ed = expected_diff.map {|dom,key| domains_and_keys[dom][key]}
  
      [b,a,ed]
    end
  end
  
  def self.included(receiver)
    receiver.send :include, Im
  end
end