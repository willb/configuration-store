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

def setup_rhubarb(kwargs=nil)
  kwargs ||= {}
  dbname = kwargs[:dbname] || ":memory:"
  classes = kwargs[:classes] || [Mrg::Grid::Config::Store, Mrg::Grid::Config::Node, Mrg::Grid::Config::Configuration, Mrg::Grid::Config::Feature, Mrg::Grid::Config::Group, Mrg::Grid::Config::Parameter, Mrg::Grid::Config::Subsystem]

  Rhubarb::Persistence::open(kwargs[:dbname])
  classes.each {|cl| cl.create_table}
end

def teardown_rhubarb
  Rhubarb::Persistence::close
end
