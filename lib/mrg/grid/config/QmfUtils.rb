# QmfUtils -- some data structure hacks to make supporting lists and sets more palatable in QMF

require 'set'

module Mrg
  module Grid
    module Config
      
      # A set modeled as a hash that maps from hash elements to true
      class FakeSet < Hash
        def self.[](*args)
          result = FakeSet.new
          args.each {|arg| result[arg] = true}
          result
        end
        
        def self.normalize(dict)
          return self[*dict.keys]
        end
        
        def to_set
          Set[*self.keys]
        end
        
        def to_a
          self.keys
        end
      end
      
      class FakeList < Hash
        def self.normalize(dict)
          dict ||= {}
          result = FakeList.new
          dict.each {|k,v| result[k.to_s] = v}
          result
        end

        def self.[](*args)
          result = FakeList.new
          (0...args.size).to_a.zip(args) do |k,v|
            # QMF map keys must be strings
            result[k.to_s] = v
          end
          result
        end
        
        def to_a
          self.sort {|a,b| a[0].to_i <=> b[0].to_i}.map {|t| t[1]}
        end
      end
    end
  end
end