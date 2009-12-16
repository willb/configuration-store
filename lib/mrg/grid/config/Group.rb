require 'spqr/spqr'
require 'rhubarb/rhubarb'

require 'mrg/grid/config/Node'
require 'mrg/grid/config/Feature'
require 'mrg/grid/config/Parameter'
require 'mrg/grid/config/QmfUtils'
require 'digest/md5'

module Mrg
  module Grid
    module Config
      class Group
        include ::Rhubarb::Persisting
        include ::SPQR::Manageable

        declare_table_name('nodegroup')
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
        
        qmf_property :uid, :uint32, :index=>true

        declare_column :name, :string

        declare_column :is_identity_group, :boolean, :default, :false
        qmf_property :is_identity_group, :boolean

        ### Schema method declarations
                
        # GetMembership 
        # * list (map/O)
        #   A set of the nodes associated with this group
        def GetMembership()
          FakeList[*NodeMembership.find_by(:grp=>self).map{|nm| nm.node.name}]
        end
        
        expose :GetMembership do |args|
          args.declare :list, :map, :out, {}
        end
        
        # GetName 
        # * name (sstr/O)
        def GetName()
          # Assign values to output parameters
          self.name ||= ""
          # Return value
          return self.name
        end
        
        expose :GetName do |args|
          args.declare :name, :sstr, :out, {}
        end
        
        # SetName 
        # * name (sstr/I)
        def SetName(name)
          # Print values of input parameters
          log.debug "SetName: name => #{name}"
          self.name = name
        end
        
        expose :SetName do |args|
          args.declare :name, :sstr, :in, {}
        end
        
        # GetFeatures 
        # * features (map/O)
        #   A list of features to be applied to this group, in priority order (that is, the first one will be applied last, to take effect after ones with less priority)
        def GetFeatures()
          # Assign values to output parameters
          features ||= {}
          # Return value
          return features
        end
        
        expose :GetFeatures do |args|
          args.declare :features, :map, :out, {}
        end
        
        # ModifyFeatures 
        # * command (sstr/I)
        #   Valid commands are 'ADD', 'REMOVE', and 'REPLACE'.
        # * features (map/I)
        #   A list of features to apply to this group dependency priority
        # * params (map/O)
        #   A map(paramName, reasonString) for parameters that need to be set as a result of the features added before the configuration will be considered valid
        def ModifyFeatures(command,fs)
          # Print values of input parameters
          log.debug "ModifyFeatureSet: command => #{command}"
          log.debug "ModifyFeatureSet: features => #{fs}"

          feats = fs.sort {|a,b| a[0] <=> b[0]}.map {|t| t[1]}.map do |fn|
            frow = Feature.find_first_by_name(fn)
            raise "invalid feature #{fn}" unless frow
            frow
          end

          case command
          when "ADD", "REMOVE" then
            feats.each do |frow|
              # Delete any prior mappings for each supplied grp in either case
              GroupFeatures.find_by(:grp=>self, :feature=>frow).each {|nm| nm.delete}

              # Add new mappings when requested
              GroupFeatures.create(:grp=>self, :feature=>frow) if command == "ADD"
            end
          when "REPLACE"
            GroupFeatures.find_by(:grp=>self).each {|nm| nm.delete}

            feats.each do |frow|
              GroupFeatures.create(:grp=>self, :feature=>frow)
            end
          end
          
          # FIXME:  not implemented from here on out
          # Assign values to output parameters
          params ||= {}
          # Return value
          return params
        end
        
        expose :ModifyFeatures do |args|
          args.declare :command, :sstr, :in, {}
          args.declare :features, :map, :in, {}
          args.declare :params, :map, :out, {}
        end
        
        # GetParams 
        # * params (map/O)
        #   A map(paramName, value) of parameters and their values that are specific to the group
        def GetParams()
          Hash[*GroupParams.find_by(:grp=>self).map {|fp| [fp.param.name, fp.value]}.flatten]
        end
        
        expose :GetParams do |args|
          args.declare :params, :map, :out, {}
        end
        
        # ModifyParams 
        # * command (sstr/I)
        #   Valid commands are 'ADD', 'REMOVE', and 'REPLACE'.
        # * params (map/I)
        #   A map(featureName, priority) of parameter/value mappings
        def ModifyParams(command,pvmap)
          # Print values of input parameters
          log.debug "ModifyParams: command => #{command}"
          log.debug "ModifyParams: params => #{pvmap}"

          params = pvmap.keys.map do |pn|
            prow = Parameter.find_first_by_name(pn)
            raise "invalid parameter #{pn}" unless prow
            prow
          end

          case command
          when "ADD", "REMOVE" then
            params.each do |prow|
              pn = prow.name

              # Delete any prior mappings for each supplied param in either case
              GroupParams.find_by(:grp=>self, :param=>prow).map {|gp| gp.delete}

              # Add new mappings when requested
              GroupParams.create(:grp=>self, :param=>prow, :value=>pvmap[pn]) if command == "ADD"
            end
          when "REPLACE"
            GroupParams.find_by(:grp=>self).map {|gp| gp.delete}

            params.each do |prow|
              pn = prow.name

              GroupParams.create(:grp=>self, :param=>prow, :value=>pvmap[pn])
            end
          end
        end
        
        expose :ModifyParams do |args|
          args.declare :command, :sstr, :in, {}
          args.declare :params, :map, :in, {}
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
