# Group:  QMF group entity
#
# Copyright (c) 2009--2010 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.require 'spqr/spqr'
require 'rhubarb/rhubarb'

require 'mrg/grid/config/Parameter'
require 'mrg/grid/config/Feature'
require 'mrg/grid/config/DataValidating'

require 'digest/md5'

module Mrg
  module Grid
    module Config
      # forward declaration
      class NodeMembership
      end

      class Group
        include ::Rhubarb::Persisting
        include ::SPQR::Manageable
        include DataValidating
        include ConfigValidating

        declare_table_name('nodegroup') # this line is necessary because you can't have a SQL table named "group"
        qmf_package_name 'com.redhat.grid.config'
        qmf_class_name 'Group'
        ### Property method declarations
        # property uid uint32 

        def uid
          @row_id
        end
        
        def Group.find_by_uid(u)
          find(u)
        end
        
        def Group.DEFAULT_GROUP
          (Group.find_first_by_name("+++DEFAULT") or Group.create(:name => "+++DEFAULT"))
        end
        
        qmf_property :uid, :uint32, :index=>true

        declare_column :name, :string

        declare_column :is_identity_group, :boolean, :default, :false
        qmf_property :is_identity_group, :bool

        ### Schema method declarations
        
        # membership 
        # * nodes (map/O)
        #   A list of the nodes associated with this group
        def membership()
          log.debug "membership called on group #{self.inspect}"
          NodeMembership.find_by(:grp=>self).map{|nm| nm.node.name}
        end

        expose :membership do |args|
          args.declare :nodes, :list, :out, "A list of node names from the nodes that are members of this group."
        end
        
        qmf_property :name, :sstr, :desc=>"This group's name."
        alias orig_name name
        alias orig_name= name=
        
        qmf_property :display_name, :sstr, :desc=>"A human-readable version of this group's name, useful for presenting names of identity groups to end-users."
        def display_name
          return "the default group" if name == "+++DEFAULT"
          return "the identity group for #{membership[0]}" if is_identity_group
          return "group #{name}"
        end
        
        # name 
        # * name (sstr/O)
        def name()
          log.debug "name called on group #{self.orig_name}"
          # Assign values to output parameters
          self.orig_name ||= ""
          # Return value
          return self.orig_name
        end
        
        # setName 
        # * name (sstr/I)
        def setName(name)
          # Print values of input parameters
          log.debug "setName: name => #{name.inspect}"
          fail(Errors.make(Errors::NAME_ALREADY_IN_USE, Errors::GROUP), "Group name #{name} is taken") if (self.name != name and Group.find_first_by_name(name))
          self.name = name
        end
        
        expose :setName do |args|
          args.declare :name, :sstr, :in, "A new name for this group; it must not be in use by another group."
        end
        
        
        qmf_property :features, :list, :desc=>"A list of features to be applied to this group, from highest to lowest priority."
        
        # features 
        # * features (map/O)
        #   A list of features to be applied to this group, in priority order (that is, the first one will be applied last, to take effect after ones with less priority)
        def features()
          log.debug "features called on group #{self.inspect}"
          feature_objs.map{|f| f.name}
        end
        
        def clearParams
          DirtyElement.dirty_group(self);
          self.modifyParams("REPLACE", {})
          0
        end
        
        expose :clearParams do |args|
          args.declare :ret, :int, :out, "0 if successful."
        end
        
        def clearFeatures
          DirtyElement.dirty_group(self);
          self.modifyFeatures("REPLACE", {})
          0
        end
        
        expose :clearFeatures do |args|
          args.declare :ret, :int, :out, "0 if successful."
        end
        
        # modifyFeatures 
        # * command (sstr/I)
        #   Valid commands are 'ADD', 'REMOVE', and 'REPLACE'.
        # * features (map/I)
        #   A list of features to apply to this group dependency priority
        # * params (map/O)
        #   A map(paramName, reasonString) for parameters that need to be set as a result of the features added before the configuration will be considered valid
        def modifyFeatures(command,feats,options={})
          # Print values of input parameters
          log.debug "modifyFeatures: command => #{command.inspect}"
          log.debug "modifyFeatures: features => #{feats.inspect}"
          
          invalid_features = []
          current_features = self.features
          
          command = command.upcase
          
          feats = feats - current_features if command == "ADD"
          
          feats = feats.uniq.map do |fn|
            frow = Feature.find_first_by_name(fn)
            invalid_features << fn unless frow
            frow
          end

          fail(Errors.make(Errors::NONEXISTENT_ENTITY, Errors::FEATURE), "Invalid features applied to #{self.display_name}:  #{invalid_features.inspect}") if invalid_features != []

          case command
          when "ADD", "REMOVE" then
            feats.each do |frow|
              # Delete any prior mappings for each supplied grp in either case
              GroupFeatures.find_by(:grp=>self, :feature=>frow).each {|nm| nm.delete}

              # Add new mappings when requested
              GroupFeatures.create(:grp=>self, :feature=>frow) if command.upcase == "ADD"
            end
          when "REPLACE" then
            GroupFeatures.find_by(:grp=>self).each {|nm| nm.delete}

            feats.each do |frow|
              GroupFeatures.create(:grp=>self, :feature=>frow)
            end
          else fail(Errors.make(Errors::BAD_COMMAND), "Invalid command #{command}")
          end
          
          DirtyElement.dirty_group(self);
          
          nil
        end
        
        expose :modifyFeatures do |args|
          args.declare :command, :sstr, :in, "Valid commands are 'ADD', 'REMOVE', and 'REPLACE'."
          args.declare :features, :list, :in, "A list of features to apply to this group, in order of decreasing priority."
          args.declare :options, :map, :in, "No options are supported at this time."
        end
        
        def addFeature(f)
          log.debug("In addFeature, with f == #{f.inspect}")
          self.modifyFeatures("ADD", [f])
        end
        
        def removeFeature(f)
          log.debug("In removeFeature, with f == #{f.inspect}")
          self.modifyFeatures("REMOVE", [f])
        end
        
        expose :addFeature do |args|
          args.declare :feature, :lstr, :in
        end

        expose :removeFeature do |args|
          args.declare :feature, :lstr, :in
        end
        
        qmf_property :params, :map, :desc=>"A map from parameter names to values as set as custom parameter mappings for this group (i.e. independently of any features that are enabled on this group)"
        
        # modifyParams 
        # * command (sstr/I)
        #   Valid commands are 'ADD', 'REMOVE', and 'REPLACE'.
        # * params (map/I)
        #   A map(featureName, priority) of parameter/value mappings
        def modifyParams(command,pvmap,options={})
          # Print values of input parameters
          log.debug "modifyParams: command => #{command.inspect}"
          log.debug "modifyParams: params => #{pvmap.inspect}"

          invalid_params = []

          prms = pvmap.keys.map do |pn|
            prow = Parameter.find_first_by_name(pn)
            invalid_params << pn unless prow
            prow
          end
          
          fail(Errors.make(Errors::NONEXISTENT_ENTITY, Errors::PARAMETER), "Invalid parameters for #{self.display_name}:  #{invalid_params.inspect}") if invalid_params != []

          command = command.upcase

          case command
          when "ADD", "REMOVE" then
            prms.each do |prow|
              pn = prow.name

              # Delete any prior mappings for each supplied param in either case
              GroupParams.find_by(:grp=>self, :param=>prow).map {|gp| gp.delete}

              # Add new mappings when requested
              GroupParams.create(:grp=>self, :param=>prow, :value=>pvmap[pn]) if command == "ADD"
            end
          when "REPLACE" then
            GroupParams.find_by(:grp=>self).map {|gp| gp.delete}

            prms.each do |prow|
              pn = prow.name

              GroupParams.create(:grp=>self, :param=>prow, :value=>pvmap[pn])
            end
          else fail(Errors.make(Errors::BAD_COMMAND), "invalid command #{command}")
          end
          
          DirtyElement.dirty_group(self);
        end
        
        expose :modifyParams do |args|
          args.declare :command, :sstr, :in, "Valid commands are 'ADD', 'REMOVE', and 'REPLACE'."
          args.declare :params, :map, :in, "A map from parameter names to values as set as custom parameter mappings for this group (i.e. independently of any features that are enabled on this group)"
          args.declare :options, :map, :in, "No options are supported at this time."
        end
        
        def apply_to(config, ss_prepend="")
          feature_objs.reverse_each do |feature|
            log.debug("applying config for #{feature.name}")
            config = feature.apply_to(config)
            log.debug("config is #{config.inspect}")
          end
          
          # apply group-specific param settings
          # XXX: doesn't check for null-v; is this a problem (not in practice, maybe in theory)
          params.each do |k,v|
            log.debug("applying config params #{k.inspect} --> #{v.inspect}")
            if (v && md = v.match(/^(>=\s*)+(.*?)\s*$/))
              v = md[2]
              config[k] = (config.has_key?(k) && config[k]) ? "#{ss_prepend}#{config[k]}, #{v}" : "#{ss_prepend}#{v}"
            else
              config[k] = v
            end
            
            log.debug("config is #{config.inspect}")
          end
          
          config
        end

        def explain(context=nil, history=nil)
          context ||= ExplanationContext.make(:group=>self.display_name, :history=>history)
          explanation = {}
          
          feature_objs.reverse_each do |feature|
            f_ctx = ExplanationContext.make(:feature=>feature.name, :how=>ExplanationContext::FEATURE_INSTALLED_ON, :whence=>context, :history=>history)
            explanation.merge!(feature.explain(f_ctx))
          end
          
          params.keys.each do |param|
            explanation[param] = ExplanationContext.make(:param=>param, :how=>ExplanationContext::PARAM_EXPLICIT, :whence=>context, :history=>history)
          end
          
          explanation
        end

        expose :explain do |args|
          args.declare :explanation, :map, :out, "A structure representing where the parameters set on this group get their values."
        end

        def getConfig
          log.debug "getConfig called for group #{self.inspect}"
          
          # prepend ">= " to stringset-valued params, because 
          # we're going to print out the config for this group.
          apply_to({}, ">= ") 
        end
        
        expose :getConfig do |args|
          args.declare :config, :map, :out, "Current parameter-value mappings for this group, including those from all enabled features and group-specific parameter mappings."
        end
        
        def feature_objs
          GroupFeatures.find_by(:grp=>self).map{|gf| gf.feature}
        end
        
        def params
          log.debug "params called on group #{self.inspect}"
          Hash[*GroupParams.find_by(:grp=>self).map {|gp| [gp.param.name, gp.value]}.flatten]
        end
      end
      
      class GroupFeatures
        include ::Rhubarb::Persisting
        declare_column :grp, :integer, references(Group, :on_delete=>:cascade)
        declare_column :feature, :integer, references(Feature, :on_delete=>:cascade)
      end
      
      class GroupParams
        include ::Rhubarb::Persisting
        declare_column :grp, :integer, references(Group, :on_delete=>:cascade)
        declare_column :param, :integer, references(Parameter, :on_delete=>:cascade)
        declare_column :value, :string
      end
    end
  end
end
