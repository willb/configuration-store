require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'digest/md5'

module Mrg
  module Grid
    module Config

      METHOD_META = [[Feature, :annotation, ::Mrg::Grid::Config::Auth::Priv::READ, []], 
                     [Feature, :clearParams, ::Mrg::Grid::Config::Auth::Priv::WRITE, []], 
                     [Feature, :explain, ::Mrg::Grid::Config::Auth::Priv::READ, []], 
                     [Feature, :modifyConflicts, ::Mrg::Grid::Config::Auth::Priv::WRITE, ["REPLACE", [], {}]], 
                     [Feature, :modifyDepends, ::Mrg::Grid::Config::Auth::Priv::WRITE, ["REPLACE", [], {}]], 
                     [Feature, :modifyIncludedFeatures, ::Mrg::Grid::Config::Auth::Priv::WRITE, ["REPLACE", [], {}]], 
                     [Feature, :modifyParams, ::Mrg::Grid::Config::Auth::Priv::WRITE, ["REPLACE", {}, {}]], 
                     [Feature, :setAnnotation, ::Mrg::Grid::Config::Auth::Priv::WRITE, [""]], 
                     [Feature, :setName, ::Mrg::Grid::Config::Auth::Priv::WRITE, ["foo"]], 
                     [Group, :addFeature, ::Mrg::Grid::Config::Auth::Priv::WRITE, ["example"]], 
                     [Group, :annotation, ::Mrg::Grid::Config::Auth::Priv::READ, []], 
                     [Group, :clearFeatures, ::Mrg::Grid::Config::Auth::Priv::WRITE, []], 
                     [Group, :clearParams, ::Mrg::Grid::Config::Auth::Priv::WRITE, []], 
                     [Group, :explain, ::Mrg::Grid::Config::Auth::Priv::READ, []], 
                     [Group, :getConfig, ::Mrg::Grid::Config::Auth::Priv::READ, []], 
                     [Group, :membership, ::Mrg::Grid::Config::Auth::Priv::READ, []], 
                     [Group, :modifyFeatures, ::Mrg::Grid::Config::Auth::Priv::WRITE, ["REPLACE", [], {}]], 
                     [Group, :modifyParams, ::Mrg::Grid::Config::Auth::Priv::WRITE, ["REPLACE", {}, {}]], 
                     [Group, :removeFeature, ::Mrg::Grid::Config::Auth::Priv::WRITE, ["example"]], 
                     [Group, :setAnnotation, ::Mrg::Grid::Config::Auth::Priv::WRITE, [""]], 
                     [Group, :setName, ::Mrg::Grid::Config::Auth::Priv::WRITE, ["foo"]], 
                     [Node, :annotation, ::Mrg::Grid::Config::Auth::Priv::READ, []], 
                     [Node, :checkConfigVersion, ::Mrg::Grid::Config::Auth::Priv::READ, [0]], 
                     [Node, :checkin, ::Mrg::Grid::Config::Auth::Priv::READ, []], 
                     [Node, :explain, ::Mrg::Grid::Config::Auth::Priv::READ, []], 
                     [Node, :getConfig, ::Mrg::Grid::Config::Auth::Priv::READ, []], 
                     [Node, :makeProvisioned, ::Mrg::Grid::Config::Auth::Priv::WRITE, []], 
                     [Node, :makeUnprovisioned, ::Mrg::Grid::Config::Auth::Priv::WRITE, []], 
                     [Node, :modifyMemberships, ::Mrg::Grid::Config::Auth::Priv::WRITE, ["REPLACE", [], {}]], 
                     [Node, :setAnnotation, ::Mrg::Grid::Config::Auth::Priv::WRITE, [""]], 
                     [Node, :whatChanged, ::Mrg::Grid::Config::Auth::Priv::READ, [0,1]], 
                     [Parameter, :annotation, ::Mrg::Grid::Config::Auth::Priv::READ, []], 
                     [Parameter, :modifyConflicts, ::Mrg::Grid::Config::Auth::Priv::WRITE, ["REPLACE", [], {}]], 
                     [Parameter, :modifyDepends, ::Mrg::Grid::Config::Auth::Priv::WRITE, ["REPLACE", [], {}]], 
                     [Parameter, :setAnnotation, ::Mrg::Grid::Config::Auth::Priv::WRITE, [""]], 
                     [Parameter, :setDefault, ::Mrg::Grid::Config::Auth::Priv::WRITE, ["foo"]], 
                     [Parameter, :setDescription, ::Mrg::Grid::Config::Auth::Priv::WRITE, ["foo"]], 
                     [Parameter, :setKind, ::Mrg::Grid::Config::Auth::Priv::WRITE, ["foo"]], 
                     [Parameter, :setMustChange, ::Mrg::Grid::Config::Auth::Priv::WRITE, [false]], 
                     [Parameter, :setRequiresRestart, ::Mrg::Grid::Config::Auth::Priv::WRITE, [false]], 
                     [Parameter, :setVisibilityLevel, ::Mrg::Grid::Config::Auth::Priv::WRITE, [1483]], 
                     [Store, :activateConfiguration, ::Mrg::Grid::Config::Auth::Priv::ACTIVATE, []], 
                     [Store, :addExplicitGroup, ::Mrg::Grid::Config::Auth::Priv::WRITE, ["foo"]], 
                     [Store, :addFeature, ::Mrg::Grid::Config::Auth::Priv::WRITE, ["foo"]], 
                     [Store, :addNode, ::Mrg::Grid::Config::Auth::Priv::WRITE, ["foo"]], 
                     [Store, :addNodeWithOptions, ::Mrg::Grid::Config::Auth::Priv::WRITE, ["foo"]], 
                     [Store, :addParam, ::Mrg::Grid::Config::Auth::Priv::WRITE, ["foo"]], 
                     [Store, :addSubsys, ::Mrg::Grid::Config::Auth::Priv::WRITE, ["foo"]], 
                     [Store, :affectedEntities, ::Mrg::Grid::Config::Auth::Priv::READ, []], 
                     [Store, :affectedNodes, ::Mrg::Grid::Config::Auth::Priv::READ, []], 
                     [Store, :checkFeatureValidity, ::Mrg::Grid::Config::Auth::Priv::READ, [[]]], 
                     [Store, :checkGroupValidity, ::Mrg::Grid::Config::Auth::Priv::READ, [[]]], 
                     [Store, :checkNodeValidity, ::Mrg::Grid::Config::Auth::Priv::READ, [[]]], 
                     [Store, :checkParameterValidity, ::Mrg::Grid::Config::Auth::Priv::READ, [[]]], 
                     [Store, :checkSubsystemValidity, ::Mrg::Grid::Config::Auth::Priv::READ, [[]]], 
                     [Store, :getDefaultGroup, ::Mrg::Grid::Config::Auth::Priv::READ, []], 
                     [Store, :getFeature, ::Mrg::Grid::Config::Auth::Priv::READ, ['example']], 
                     [Store, :getGroup, ::Mrg::Grid::Config::Auth::Priv::READ, [{"NAME"=>'example'}]], 
                     [Store, :getGroupByName, ::Mrg::Grid::Config::Auth::Priv::READ, ['example']], 
                     [Store, :getMustChangeParams, ::Mrg::Grid::Config::Auth::Priv::READ, []], 
                     [Store, :getNode, ::Mrg::Grid::Config::Auth::Priv::READ, ['example']], 
                     [Store, :getParam, ::Mrg::Grid::Config::Auth::Priv::READ, ['example']], 
                     [Store, :getSkeletonGroup, ::Mrg::Grid::Config::Auth::Priv::READ, []], 
                     [Store, :getSubsys, ::Mrg::Grid::Config::Auth::Priv::READ, ['example']], 
                     [Store, :loadSnapshot, ::Mrg::Grid::Config::Auth::Priv::ADMIN, ['example']], 
                     [Store, :makeSnapshot, ::Mrg::Grid::Config::Auth::Priv::WRITE, ['foo']], 
                     [Store, :makeSnapshotWithOptions, ::Mrg::Grid::Config::Auth::Priv::WRITE, ['foo']], 
                     [Store, :removeFeature, ::Mrg::Grid::Config::Auth::Priv::WRITE, ['example']], 
                     [Store, :removeGroup, ::Mrg::Grid::Config::Auth::Priv::WRITE, ['example']], 
                     [Store, :removeNode, ::Mrg::Grid::Config::Auth::Priv::WRITE, ['example']], 
                     [Store, :removeParam, ::Mrg::Grid::Config::Auth::Priv::WRITE, ['example']], 
                     [Store, :removeSnapshot, ::Mrg::Grid::Config::Auth::Priv::ADMIN, ['example']], 
                     [Store, :removeSubsys, ::Mrg::Grid::Config::Auth::Priv::WRITE, ['example']], 
                     [Store, :storeinit, ::Mrg::Grid::Config::Auth::Priv::ADMIN, []], 
                     [Store, :validateConfiguration, ::Mrg::Grid::Config::Auth::Priv::READ, []], 
                     [Subsystem, :annotation, ::Mrg::Grid::Config::Auth::Priv::READ, []], 
                     [Subsystem, :modifyParams, ::Mrg::Grid::Config::Auth::Priv::WRITE, ["REPLACE", [], {}]],
                     [Subsystem, :setAnnotation, ::Mrg::Grid::Config::Auth::Priv::WRITE, [""]]]

        
      def helper_access_allowed?(mine, required)
        if mine.is_a?(Array)
          highest = mine.map {|p| ::Mrg::Grid::Config::Auth::Priv.const_get(p)}.max

          return highest >= required
        end
        
        return mine == :authorized || (::Mrg::Grid::Config::Auth::Priv.const_get(mine) >= required rescue false)
      end
      
      def helper_get_instance(klazz, name="example")
        if klazz == Store 
          return @store
        end
      
        msg_for = {Group=>:getGroupByName, Feature=>:getFeature, Parameter=>:getParam, Node=>:getNode, Subsystem=>:getSubsys}
      
        @store.send(msg_for[klazz], name)
      end
      

      # we want to cover the following cases:
      # 0.  users who are not authorized at all with an empty userdb
      # 1.  users who are not authorized at all with a populated userdb
      # 2.  users who are explicitly authorized and acting within their authority
      # 3.  users who are explicitly authorized but acting in excess of their authority
      # 4.  users who are implicitly authorized and acting within their authority
      # 5.  users who are implicitly authorized but acting in excess of their authority

      # [[:default, :authorized], [:default, :unauthorized]] +
      #  [:explicit, :implicit].inject([]) {|acc,x| acc += %w{NONE READ WRITE ADMIN}.inject([]) {|acc,y| acc << [x,y]}} + 
      #  %w{NONE READ WRITE ADMIN}.inject([]) {|acc, x| acc += %w{NONE READ WRITE ADMIN}.inject([]) {|acc, y| acc << [:hybrid, [x, y]]}}.each do |dbstate, access|

            
      [[:default, :authorized], [:default, :unauthorized]] +
       [:explicit, :implicit].inject([]) {|acc,x| acc += %w{NONE READ WRITE ADMIN}.inject([]) {|acc,y| acc << [x,y]}} +
       (%w{NONE READ WRITE ADMIN}.inject([]) {|acc, x| acc += %w{NONE READ WRITE ADMIN}.inject([]) {|acc, y| acc << [:hybrid, [x, y]]}}).each do |dbstate, access|
        describe "#{dbstate} authorization for users #{[:authorized, :unauthorized].include?(access) ? "who are #{access}" : "with #{access.is_a?(Array) ? "explicit/implicit" : ""} privilege level #{access.inspect}"}" do        
          before(:all) do
            @STRUCT = Struct.new(:username, :privs)
          end
          
          before(:each) do
            setup_rhubarb
            @store = Store.new
            @saved_user = Thread.current[:qmf_user_id]
            
            [:addExplicitGroup, :addFeature, :addNode, :addParam, :addSubsys, :makeSnapshot].each do |msg|
              @store.send(msg, "example")
            end
            
            if access == :authorized
              ::Mrg::Grid::Config::Auth::RoleCache.populate([])
            elsif access == :unauthorized
              ::Mrg::Grid::Config::Auth::RoleCache.populate([@STRUCT.new("superuser", ::Mrg::Grid::Config::Auth::Priv::ADMIN)])
            elsif access.is_a?(Array)
              roles = ["foonly", "*"].zip(access).map do |username,acs| 
                priv = ::Mrg::Grid::Config::Auth::Priv.const_get(acs)
                @STRUCT.new(username, priv)
              end
                
              ::Mrg::Grid::Config::Auth::RoleCache.populate(roles)
            else
              username = (dbstate == :explicit ? "foonly" : "*")
              privs = ::Mrg::Grid::Config::Auth::Priv.const_get(access)
              ::Mrg::Grid::Config::Auth::RoleCache.populate([@STRUCT.new(username, privs)])
            end
            Thread.current[:qmf_user_id] = "foonly"
          end
          
          METHOD_META.select {|kl, msg, perm, args| helper_access_allowed?(access, perm)}.each do |kl, msg, perm, args|
            it "should allow access to #{kl}##{msg}" do
              lambda { obj = helper_get_instance(kl) ;  obj.send(msg, *args)}.should_not raise_error(SPQR::ManageableObjectError, /cannot invoke/)
            end

            it "should successfully call #{kl}##{msg}" do
              obj = helper_get_instance(kl)
              obj.send(msg, *args)
            end
          end

          METHOD_META.select {|kl, msg, perm, args| not helper_access_allowed?(access, perm)}.each do |kl, msg, perm, args|
            it "should NOT allow access to #{kl}##{msg}" do
              lambda { obj = helper_get_instance(kl) ;  obj.send(msg, *args)}.should raise_error(SPQR::ManageableObjectError, /cannot invoke/)
            end
          end
          
          after(:each) do
            teardown_rhubarb
            Thread.current[:qmf_user_id] = @saved_user
            ::Mrg::Grid::Config::Auth::RoleCache.populate([])
          end
        end
      end
    end
  end
end