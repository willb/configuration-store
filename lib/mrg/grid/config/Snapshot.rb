require 'mrg/grid/config'
require 'zlib'
require 'sqlite3'

module Mrg
  module Grid
    module Config
      class Snapshot
        include ::Rhubarb::Persisting
        include ::SPQR::Manageable

        qmf_package_name 'mrg.grid.config'
        qmf_class_name 'Subsystem'
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
          self.orig_snaptext = SQLite::Blob.new(Zlib::Deflate.deflate(st, Zlib::BEST_COMPRESSION))
        end
    end
  end
end
