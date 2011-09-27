# Snapshot:  models wallaby snapshots
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

require 'mrg/grid/config'
require 'zlib'
require 'sqlite3'
require 'rhubarb/rhubarb'

module Mrg
  module Grid
    module Config
      class Snapshot
        include ::Rhubarb::Persisting
        include ::SPQR::Manageable

        qmf_package_name 'com.redhat.grid.config'
        qmf_class_name 'Snapshot'
        ### Property method declarations
        # property name sstr 

        declare_column :name, :string, :not_null
        declare_index_on :name
        
        qmf_property :name, :sstr, :index=>true
        
        declare_column :snaptext, :blob
        
        alias orig_snaptext snaptext
        alias orig_snaptext= snaptext=
        
        def snaptext
          Zlib::Inflate.inflate(orig_snaptext)
        end
        
        def snaptext=(st)
          self.orig_snaptext = SQLite3::Blob.new(Zlib::Deflate.deflate(st, Zlib::BEST_COMPRESSION))
        end

        def self.autogen_name(prefix)
          t = Time.now.utc
          "#{prefix} at #{t} -- #{::Rhubarb::Util::timestamp.to_s(16)}"
        end
      end
    end
  end
end
