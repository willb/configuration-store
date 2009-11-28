require 'spqr/spqr'
require 'spqr/app'

require 'mrg/grid/config/Store'
require 'mrg/grid/config/Node'
require 'mrg/grid/config/Configuration'
require 'mrg/grid/config/Feature'
require 'mrg/grid/config/Group'
require 'mrg/grid/config/Parameter'
require 'mrg/grid/config/Subsystem'

app = SPQR::App.new(:loglevel => :debug)
app.register Mrg::Grid::Config::Store,Mrg::Grid::Config::Node,Mrg::Grid::Config::Configuration,Mrg::Grid::Config::Feature,Mrg::Grid::Config::Group,Mrg::Grid::Config::Parameter,Mrg::Grid::Config::Subsystem

app.main
