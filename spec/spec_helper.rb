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

Store.quiesce(:ENABLE_SKELETON_GROUP, true)

def setup_rhubarb(kwargs=nil)
  kwargs ||= {}
  dbname = kwargs[:dbname] || ":memory:"
  snapdbname = kwargs[:snapdb] || dbname

  db_classes = kwargs[:db_classes] || MAIN_DB_TABLES 
  snap_classes = kwargs[:snap_classes] || SNAP_DB_TABLES

  Rhubarb::Persistence::open(dbname, :default, false)
  Rhubarb::Persistence::open(snapdbname, :snapshots, false)

  {:default=>db_classes, :snapshots=>snap_classes}.each do |dbkey, klasses|  
    klasses.each {|cl| cl.db = Rhubarb::Persistence::dbs[dbkey]}
    klasses.each {|cl| cl.create_table rescue nil}
  end


  Group.DEFAULT_GROUP
  Group.SKELETON_GROUP
end

def teardown_rhubarb
  (MAIN_DB_TABLES + SNAP_DB_TABLES).each {|tab| tab.delete_all}
  Rhubarb::Persistence::close(:default)
  Rhubarb::Persistence::close(:snapshots)
  (MAIN_DB_TABLES + SNAP_DB_TABLES).each {|tab| tab.db = nil}
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
  def reconstitute_db(text=nil)
    pending "You've disabled tests involving the full database for this run" if ENV['WALLABY_SKIP_EXPENSIVE_TESTS']

    text ||= dbtext

    $wallaby_skip_inconsistency_detection = true
    
    @store.storeinit("resetdb"=>"yes")
    s = Mrg::Grid::SerializedConfigs::ConfigLoader.new(@store, text)
    s.load
    
    $wallaby_skip_inconsistency_detection = false
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

module BigPoolFixture
  include BaseDBFixture
  def dbtext
    open("#{File.dirname(__FILE__)}/big-pool.yaml", "r") {|db| db.read}
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

module PatchTester
  include Mrg::Grid::SerializedConfigs::DBHelpers

  def patch_db(args)
    @versions = []
    affected = {}
    args ||= {}
    defaults = {:files=>[], :dir=>"/var/lib/wallaby/patches", :exit_code=>0, :cmd_args=>[]}
    args = defaults.merge(args)
    dir = args[:dir]

    details = Hash.new {|h,k| h[k] = Hash.new {|h1,k1| h1[k1] = {} } }
    patcher = Mrg::Grid::PatchConfigs::PatchLoader.new(@store, false)
    Dir.mkdir(dir) rescue nil
    prev_f = ""
    args[:files].each do |f|
      if f != "." and f != ".."
        FileUtils.cp(f, dir)
        filename = "#{dir}/#{File.basename(f)}"
        if prev_f != ""
          prev_v, next_v = setup_to_trail(prev_f, filename)
          @versions = @versions + ([prev_v, next_v] - @versions)
        end
        prev_f = filename
      end
    end
    Mrg::Grid::Config::Shell::Upgrade_db.new(@store, "").main(["-v", "-d", "#{dir}"] + args[:cmd_args]).should == args[:exit_code]
    args[:files].each do |f|
      patcher.load_yaml(open("#{dir}/#{File.basename(f)}", "r") {|db| db.read})
      new = patcher.affected_entities
      affected.merge!(new)
      new.keys.each do |changed|
        new[changed].each do |type, names|
          names.each do |n|
            details[type][n].merge!(patcher.entity_details(type, n))
          end
        end
      end
    end
    [details, affected]
  end

  def verify_changes(details, affected)
    affected.keys.each do |changed|
      affected[changed].each do |type, names|
        names.each do |n|
          if changed == :delete
            @store.send("check#{type}Validity", [n]).should == [n]
          else
            @store.send("check#{type}Validity", [n]).should == []
            if type == :Group
              obj = @store.send("getGroupByName", n)
            else
              method = Mrg::Grid::Config::Store.instance_methods(false).map{|ms| ms.to_s}.grep(/^get#{type.to_s.slice(0,5).capitalize}/)
              obj = @store.send(method.pop.to_s, n)
            end
            obj.should_not == nil
            details[type][n][:updates].each do |get, value|
              obj.send(get).should == value
            end
          end
        end
      end
    end
  end

  def setup_to_trail(prev, nextf)
    reader = Mrg::Grid::PatchConfigs::PatchLoader.new(@store, false)
    reader.load_yaml(open("#{prev}", "r") {|db| db.read})
    ver1 = reader.db_version
    fhdl = open(nextf, 'r')
    contents = ""
    old = 0
    fhdl.read.each_line do |line|
      if line =~ /BaseDBVersion:\s*v(.+)$/
        if old == 0
          old = $1
        end
      end
      contents += line
    end
    fhdl.close
    fhdl = open(nextf, 'w')
    ver2 = 0
    contents.each_line do |line|
      if line =~ /^db_version:\s*"(.*)"$/
        ver2 = $1
      end
      if line =~ /(.*)BaseDBVersion:(\s*)v#{old}/
        fhdl.write("#{$1}BaseDBVersion:#{$2}v#{ver1}")
      else
        fhdl.write(line)
      end
    end
    fhdl.close
    [ver1, ver2]
  end

  def get_store_contents
    Mrg::Grid::SerializedConfigs::ConfigSerializer.new(@store).serialize
  end

  def verify_store(old_store)
    cur_store = get_store_contents
    cur_store.public_methods(false).map{|ms| ms.to_s}.select {|m| m.index("=") == nil}.each do |type|
      cur_store.send(type).each do |obj|
        methods = obj.public_methods(false).map{|ms| ms.to_s}.select {|m| m.index("=") == nil}
        old_obj = old_store.send(type).select {|o| o.name == obj.name}[0]
        methods.each do |m|
          obj.send(m).should == old_obj.send(m)
        end
      end
    end
  end

  def change_expectations_then_patch(args)
    args ||= {}
    defaults = {:skip_patterns=>[]}
    args = defaults.merge(args)
    patcher = Mrg::Grid::PatchConfigs::PatchLoader.new(@store, false)
    snap_name = "Pre-Change"
    extra_feat = "ExtraFeature"
    extra_group = "ExtraGroup"
    extra_param = "EXTRA_PARAM"

    @store.addFeature(extra_feat)
    @store.addExplicitGroup(extra_group)
    @store.makeSnapshot(snap_name)

    patcher.load_yaml(open("#{args[:files][0]}", "r") {|db| db.read})
    affected = patcher.affected_entities
    [:modify, :delete].each do |changed|
      affected[changed].each do |type, names|
        klass = Mrg::Grid::Config.const_get(type)
        names.each do |n|
          skip = false
          args[:skip_patterns].each do |s|
            if n.to_s.index(s) != nil
              skip = true
              break
            end
          end
          if skip
            next
          end
          @store.send("check#{type}Validity", [n]).should == []
          dets = patcher.entity_details(type, n)
          dets[:expected].each do |getter, value|
            t = Time.now.utc
            new_val = (t.tv_sec * 1000000) + t.tv_usec
            if type == :Group
              obj = @store.send("getGroupByName", n)
            else
              method = Mrg::Grid::Config::Store.instance_methods(false).map{|ms|ms.to_s}.grep(/^get#{type.to_s.slice(0,5).capitalize}/)
              obj = @store.send(method.pop.to_s, n)
            end
            obj.should_not == nil
            getter = getter.to_sym
            cmd = klass.set_from_get(getter)
            if cmd.to_s =~ /^modifyParams/ and (type == :Feature or type == :Group)
              obj.send(cmd, "REPLACE", {"EXTRA_PARAM"=>new_val}, {})
            elsif cmd.to_s =~ /^modify/
              if type == :Feature or type == :Group
                obj.send(cmd, "REPLACE", [extra_feat], {})
              elsif type == :Parameter
                obj.send(cmd, "REPLACE", [extra_param], {})
              elsif type == :Node
                obj.send(cmd, "REPLACE", [extra_group], {})
              else
                # Subsystem
                obj.send(cmd, "REPLACE", [extra_param], {})
              end
            else
              obj.send(cmd, new_val)
            end

            state = get_store_contents
            patch_db(args)
            verify_store(state)
            @store.loadSnapshot(snap_name)
          end
        end
      end
    end
  end
end
