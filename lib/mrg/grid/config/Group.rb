require 'spqr/spqr'
require 'rhubarb/rhubarb'

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

        declare_column :uid, :integer, :not_null
        declare_index_on :uid
        
        qmf_property :uid, :uint32, :index=>true
        ### Schema method declarations
        
        # ModifyMembership 
        # * command (sstr/I)
        #   Valid commands are 'ADD', 'REMOVE', 'UNION', 'INTERSECT', 'DIFF', and 'REPLACE'.
        # * nodes (map/I)
        #   A set of nodes
        # * options (map/I)
        def ModifyMembership(command,nodes,options)
          # Print values of input parameters
          log.debug "ModifyMembership: command => #{command}"
          log.debug "ModifyMembership: nodes => #{nodes}"
          log.debug "ModifyMembership: options => #{options}"
        end
        
        expose :ModifyMembership do |args|
          args.declare :command, :sstr, :in, {}
          args.declare :nodes, :map, :in, {}
          args.declare :options, :map, :in, {}
        end
        
        # GetMembership 
        # * list (map/O)
        #   A set of the nodes associated with this group
        def GetMembership()
          # Assign values to output parameters
          list ||= {}
          # Return value
          return list
        end
        
        expose :GetMembership do |args|
          args.declare :list, :map, :out, {}
        end
        
        # GetName 
        # * name (sstr/O)
        def GetName()
          # Assign values to output parameters
          name ||= ""
          # Return value
          return name
        end
        
        expose :GetName do |args|
          args.declare :name, :sstr, :out, {}
        end
        
        # SetName 
        # * name (sstr/I)
        def SetName(name)
          # Print values of input parameters
          log.debug "SetName: name => #{name}"
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
        
        # ModifyFeaturePriorities 
        # * features (map/IO)
        #   A list of features in this group (as returned by GetFeatures), in a new priority order. Features that are in this list but not in the group will be ignored. Features that are in the group but not in this list will be placed in arbitrary priority order after every feature in this list. After this method executes, features will contain the priority ordering of every feature assigned to this group.
        def ModifyFeaturePriorities(features)
          # Print values of input parameters
          log.debug "ModifyFeaturePriorities: features => #{features}"
          # Assign values to output parameters
          features ||= {}
          # Return value
          return features
        end
        
        expose :ModifyFeaturePriorities do |args|
          args.declare :features, :map, :inout, {}
        end
        
        # ModifyFeatureSet 
        # * command (sstr/I)
        #   Valid commands are 'ADD', 'REMOVE', 'UNION', 'INTERSECT', 'DIFF', and 'REPLACE'.
        # * features (map/I)
        #   A set of features to apply to dependency priority
        # * params (map/O)
        #   A map(paramName, reasonString) for parameters that need to be set as a result of the features added before the configuration will be considered valid
        def ModifyFeatureSet(command,features)
          # Print values of input parameters
          log.debug "ModifyFeatureSet: command => #{command}"
          log.debug "ModifyFeatureSet: features => #{features}"
          # Assign values to output parameters
          params ||= {}
          # Return value
          return params
        end
        
        expose :ModifyFeatureSet do |args|
          args.declare :params, :map, :out, {}
          args.declare :command, :sstr, :in, {}
          args.declare :features, :map, :in, {}
        end
        
        # GetParams 
        # * params (map/O)
        #   A map(paramName, value) of parameters and their values that are specific to the group
        def GetParams()
          # Assign values to output parameters
          params ||= {}
          # Return value
          return params
        end
        
        expose :GetParams do |args|
          args.declare :params, :map, :out, {}
        end
        
        # ModifyParams 
        # * command (sstr/I)
        #   Valid commands are 'ADD', 'REMOVE', 'UNION', 'INTERSECT', 'DIFF', and 'REPLACE'.
        # * params (map/I)
        #   A map(featureName, priority) of feature names and their dependency priority
        def ModifyParams(command,params)
          # Print values of input parameters
          log.debug "ModifyParams: command => #{command}"
          log.debug "ModifyParams: params => #{params}"
        end
        
        expose :ModifyParams do |args|
          args.declare :command, :sstr, :in, {}
          args.declare :params, :map, :in, {}
        end
      end
    end
  end
end
