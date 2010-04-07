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
require 'mrg/grid/config/QmfUtils'
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
        qmf_package_name 'mrg.grid.config'
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
                
        # getMembership 
        # * nodes (map/O)
        #   A list of the nodes associated with this group
        def getMembership()
          log.debug "getMembership called on group #{self.inspect}"
          NodeMembership.find_by(:grp=>self).map{|nm| nm.node.name}
        end
        
        expose :getMembership do |args|
          args.declare :nodes, :list, :out, {}
        end
        
        # getName 
        # * name (sstr/O)
        def getName()
          log.debug "getName called on group #{self.inspect}"
          # Assign values to output parameters
          self.name ||= ""
          # Return value
          return self.name
        end
        
        expose :getName do |args|
          args.declare :name, :sstr, :out, {}
        end
        
        # setName 
        # * name (sstr/I)
        def setName(name)
          # Print values of input parameters
          log.debug "setName: name => #{name.inspect}"
          fail(42, "Group name #{name} is taken") if (self.name != name and Group.find_first_by_name(name))
          self.name = name
        end
        
        expose :setName do |args|
          args.declare :name, :sstr, :in, {}
        end
        
        # getFeatures 
        # * features (map/O)
        #   A list of features to be applied to this group, in priority order (that is, the first one will be applied last, to take effect after ones with less priority)
        def getFeatures()
          log.debug "getFeatures called on group #{self.inspect}"
          features.map{|f| f.name}
        end
        
        expose :getFeatures do |args|
          args.declare :features, :list, :out, {}
        end
        
        def clearParams
          DirtyElement.dirty_group(self);
          self.modifyParams("REPLACE", {})
          0
        end
        
        expose :clearParams do |args|
          args.declare :ret, :int, :out, {}
        end
        
        def clearFeatures
          DirtyElement.dirty_group(self);
          self.modifyFeatures("REPLACE", {})
          0
        end
        
        expose :clearFeatures do |args|
          args.declare :ret, :int, :out, {}
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
          
          feats = feats.map do |fn|
            frow = Feature.find_first_by_name(fn)
            invalid_features << fn unless frow
            frow
          end

          fail(42, "Invalid features applied to group #{self.name}:  #{invalid_features.inspect}") if invalid_features != []

          command = command.upcase

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
          else fail(7, "invalid command #{command}")
          end
          
          DirtyElement.dirty_group(self);
          
          # FIXME:  not implemented from here on out
          # Assign values to output parameters
          params ||= {}
          # Return value
          return params
        end
        
        expose :modifyFeatures do |args|
          args.declare :command, :sstr, :in, {}
          args.declare :features, :list, :in, {}
          args.declare :options, :map, :in, {}
          args.declare :params, :map, :out, {}
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
        
        # getParams 
        # * params (map/O)
        #   A map(paramName, value) of parameters and their values that are specific to the group
        def getParams()
          log.debug "getParams called on group #{self.inspect}"
          Hash[*GroupParams.find_by(:grp=>self).map {|fp| [fp.param.name, fp.value]}.flatten]
        end
        
        expose :getParams do |args|
          args.declare :params, :map, :out, {}
        end
        
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

          params = pvmap.keys.map do |pn|
            prow = Parameter.find_first_by_name(pn)
            invalid_params << pn unless prow
            prow
          end
          
          fail(42, "Invalid parameters for group #{self.name}:  #{invalid_params.inspect}") if invalid_params != []

          command = command.upcase

          case command
          when "ADD", "REMOVE" then
            params.each do |prow|
              pn = prow.name

              # Delete any prior mappings for each supplied param in either case
              GroupParams.find_by(:grp=>self, :param=>prow).map {|gp| gp.delete}

              # Add new mappings when requested
              GroupParams.create(:grp=>self, :param=>prow, :value=>pvmap[pn]) if command == "ADD"
            end
          when "REPLACE" then
            GroupParams.find_by(:grp=>self).map {|gp| gp.delete}

            params.each do |prow|
              pn = prow.name

              GroupParams.create(:grp=>self, :param=>prow, :value=>pvmap[pn])
            end
          else fail(7, "invalid command #{command}")
          end
          
          DirtyElement.dirty_group(self);
        end
        
        expose :modifyParams do |args|
          args.declare :command, :sstr, :in, {}
          args.declare :params, :map, :in, {}
          args.declare :options, :map, :in, {}
        end
        
        def apply_to(config, ss_prepend="")
          features.reverse_each do |feature|
            log.debug("applying config for #{feature.name}")
            config = feature.apply_to(config)
            log.debug("config is #{config.inspect}")
          end
          
          # apply group-specific param settings
          # XXX: doesn't check for null-v; is this a problem (not in practice, maybe in theory)
          params.each do |k,v|
            log.debug("applying config params #{k.inspect} --> #{v.inspect}")
            if (v && v.slice!(/^>=/))
              while v.slice!(/^>=/) ;  v.strip! ; end
              config[k] = (config.has_key?(k) && config[k]) ? "#{ss_prepend}#{config[k]}, #{v.strip}" : "#{ss_prepend}#{v.strip}"
            else
              config[k] = v
            end
            
            log.debug("config is #{config.inspect}")
          end
          
          config
        end

        def getConfig
          log.debug "getConfig called for group #{self.inspect}"
          
          # prepend ">= " to stringset-valued params, because 
          # we're going to print out the config for this group.
          apply_to({}, ">= ") 
        end
        
        expose :getConfig do |args|
          args.declare :config, :map, :out, {}
        end
        
        def features
          GroupFeatures.find_by(:grp=>self).map{|gf| gf.feature}
        end
        
        def params
          Hash[*GroupParams.find_by(:grp=>self).map{|gp| [gp.param.name, gp.value]}.flatten]
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
