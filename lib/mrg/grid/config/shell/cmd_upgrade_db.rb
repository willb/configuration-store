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
        
          def supports_options
            true
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

              opts.on("-d", "--directory VALUE", "directory containing patch files") do |dir|
                @patch_dir = dir
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
            patcher = Mrg::Grid::SerializedConfigs::PatchLoader.new(store, @force)

            files = Dir.entries(@patch_dir)
            files.delete(".")
            files.delete("..")
            files.sort! {|x, y| split = y.split(".")
                                y_maj = split[0].to_i
                                y_min = split[1].to_i
                                split = x.split(".")
                                x_maj = split[0].to_i
                                x_min = split[1].to_i
                                (x_maj > y_maj) or (x_maj <=> y_maj and x_min <=> y_min)}
            files.each do |file|
              if not File.directory?(file)
                fhdl = open("#{@patch_dir}/#{file}")
                patcher.load_yaml(fhdl.read)
                begin
                  patcher.load
                rescue Exception=>ex
                  patcher.revert_db
                  exit!(1, "Database upgrade failed. #{ex.message}")
                end
              end
            end
            puts "Database upgrade completed successfully"
          end
        end
      end
    end
  end
end
