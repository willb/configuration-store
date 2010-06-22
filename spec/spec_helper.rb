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
