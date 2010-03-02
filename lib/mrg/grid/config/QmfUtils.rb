# QmfUtils: some data structure hacks to make supporting lists and sets more palatable in QMF
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
# limitations under the License.

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
        
        def to_h
          {}.merge(self)
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