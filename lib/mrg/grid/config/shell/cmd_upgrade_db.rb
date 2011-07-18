# cmd_upgrade_db.rb:  
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
      module Shell
        class Upgrade_db < ::Mrg::Grid::Config::Shell::Command
          # opname returns the operation name; for "wallaby foo", it
          # would return "foo".
          def self.opname
            "upgrade-db"
          end
        
          # description returns a short description of this command, suitable 
          # for use in the output of "wallaby help commands".
          def self.description
            "Upgrade the wallaby database."
          end
        
          def init_option_parser
            # Edit this method to generate a method that parses your command-line options.
            @force = false
            OptionParser.new do |opts|
              opts.banner = "Usage:  wallaby #{self.class.opname}\n#{self.class.description}"
        
              opts.on("-h", "--help", "displays this message") do
                puts @oparser
                exit
              end

              opts.on("-f", "--force", "force upgrade") do
                @force = true
              end
            end
          end
        
          def init_patch_dir(*args)
             @patch_dir = "/var/lib/wallaby/patches"
          end

          register_callback :before_option_parsing, :init_patch_dir

          def init_log(*args)
            Mrg::Grid::SerializedConfigs::PatchLoader.log = LoadSupport::SimpleLog.new(:info)
          end

          register_callback :before_option_parsing, :init_log

          def act
#            fobj = store.getFeature("BaseDBVersion")
#            if fobj != nil:
#              db_ver = (fobj.params["BaseDBVersion"].to_s rescue 0)
#              temp = db_ver.split('.')
#              db_major = temp[0].to_i
#              db_minor = temp[1].to_i
#            else
#              db_major = 0
#              db_minor = 0
#            end
#  
#            if db_major > 1 or (db_major <= 1 and db_minor >= 14)
#              puts "The database is up to date"
#            else
#              t = Time.now.utc
#              @snap_name = "Database upgrade automatically generated snapshot at #{t} -- #{((t.tv_sec * 1000000) + t.tv_usec).to_s(16)}"
#  
#              puts "Creating pre-upgrade snapshot named #{@snap_name}"
#              if store.makeSnapshot(@snap_name) == nil
#                 exit!(1, "Failed to create pre-upgrade snapshot.  Database upgrade aborted")
#              end

            patcher = Mrg::Grid::SerializedConfigs::PatchLoader.new(store, "")

            Dir.foreach(@patch_dir) do |file|
              if not File.directory?(file)
                patcher.init_from_yaml(file.read)
                begin
                  patcher.load
                rescue Exception=>ex
                  patch.revert_db
                  exit!(1, "Database upgrade failed. #{ex.message}")
                end
              end
            end
          end
        end
      end
    end
  end
end
