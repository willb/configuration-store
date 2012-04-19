# dbmeta.rb:  database support code and migrations
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

module Mrg
  module Grid
    module Config
      MAIN_DB_TABLES=[Mrg::Grid::Config::Feature, Mrg::Grid::Config::Group, Mrg::Grid::Config::Parameter, Mrg::Grid::Config::Subsystem, Mrg::Grid::Config::Node, Mrg::Grid::Config::ArcLabel, Mrg::Grid::Config::ParameterArc, Mrg::Grid::Config::FeatureArc, Mrg::Grid::Config::FeatureParams, Mrg::Grid::Config::NodeMembership, Mrg::Grid::Config::GroupParams, Mrg::Grid::Config::GroupFeatures, Mrg::Grid::Config::SubsystemParams, Mrg::Grid::Config::DirtyElement]
      SNAP_DB_TABLES=[Mrg::Grid::Config::Snapshot, Mrg::Grid::Config::ConfigVersion, Mrg::Grid::Config::VersionedNode, Mrg::Grid::Config::VersionedParam, Mrg::Grid::Config::VersionedNodeConfig, Mrg::Grid::Config::VersionedNodeParamMapping]
      DBVERSION = 6
      DBMIGRATIONS = []

      SNAPVERSION = 1
      SNAPMIGRATIONS = []
          
      module DBSchema
        DB_MIGRATION_DIR = File.join(File.expand_path(File.dirname(__FILE__)), "dbmigrate")
        
        def self.require_migrations
          migrations = Dir["#{Mrg::Grid::Config::DBSchema::DB_MIGRATION_DIR}/*.rb"]
        
          migrations.each do |m|
            require File.join(File.dirname(m), File.basename(m, File.extname(m)))
          end
        end
      
        class Sink
          [:fatal, :error, :warn, :info, :debug].each do |m|
            define_method m do |*args|
              if block_given?
                puts "#{m}: #{yield}"
              else
                puts "#{m}: #{args.join(" ")}"
              end
              nil
            end
          end
        end
      
        def self.migrate(db, tables, migrations, log=nil)
          log ||= Sink.new
        
          tables.each do |cl| 
            log.info "creating table for #{cl.name} if necessary..."
            cl.create_table rescue nil
          end

          observed_version = db.get_first_value("PRAGMA user_version").to_i
          version = observed_version

          to_apply = migrations.slice(observed_version + 1, migrations.size)
        
          unless to_apply == []
            log.info "found #{to_apply.size} migrations"
            yield observed_version if block_given?
          end

          to_apply.each do |migration|
            log.info "bringing db up to version #{observed_version + 1}"
            (migration.arity == 1 ? migration.call(db) : migration.call) if migration
            observed_version = db.get_first_value("PRAGMA user_version").to_i
            log.info "db is at version #{observed_version}"
          end
        end
      end
    end
  end
end

::Mrg::Grid::Config::DBSchema.require_migrations