$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rubygems'

require 'mrg/grid/config/Store'
require 'mrg/grid/config/Node'
require 'mrg/grid/config/Configuration'
require 'mrg/grid/config/Feature'
require 'mrg/grid/config/Group'
require 'mrg/grid/config/Parameter'
require 'mrg/grid/config/Subsystem'

require 'spec'
require 'spec/autorun'

Spec::Runner.configure do |config|
  
end

include Mrg::Grid::Config

def setup_rhubarb(kwargs=nil)
  kwargs ||= {}
  dbname = kwargs[:dbname] || ":memory:"
  classes = kwargs[:classes] || [Node, Configuration, Feature, Group, Parameter, Subsystem]

  Rhubarb::Persistence::open(dbname)
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