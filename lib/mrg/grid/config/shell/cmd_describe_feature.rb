# cmd_describe_feature.rb:  describes a feature and its relationships
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
        class DescribeFeature < ::Mrg::Grid::Config::Shell::Command
          # opname returns the operation name; for "wallaby foo", it
          # would return "foo".
          def self.opname
            "describe-feature"
          end
        
          # description returns a short description of this command, suitable 
          # for use in the output of "wallaby help commands".
          def self.description
            "describes a feature and its relationships"
          end
        
          def init_option_parser
            # Edit this method to generate a method that parses your command-line options.
            OptionParser.new do |opts|
              opts.banner = "Usage:  wallaby #{self.class.opname}\n#{self.class.description}"
        
              opts.on("-h", "--help", "displays this message") do
                puts @oparser
                exit
              end

              opts.on("-x", "--transitive", "also describes all features transitively related to this one") do
                @transitive = true
              end

              opts.on("--json", "output in JSON format") do
                @json = true
              end
            end
          end
        
          def act
            # This method is responsible for actually performing the work of
            # the command. It may read the @kwargs instance variable, which
            # should be a hash, and must return an integer, corresponding to
            # the exit code of the command.
        
            # It may access the wallaby store with the "store" method; it will
            # only connect to the wallaby store after the first time "store" is
            # invoked. See the Wallaby client API for more information on
            # methods supported by store and other Wallaby API entities.
        
            # You may exit the command from a callee of act by using the exit!
            # method, which takes a status code and an optional explanation of
            # why you are exiting. For example:
        
            # exit!(1, "Did nothing, unsuccessfully.")
            worklist = @args.uniq
            seen = Set[*worklist]
            exitcode = 0

            puts '{"features": [\n' if @json
            
            while worklist != []
              current_feature = worklist.shift
              seen << current_feature
              f = store.getFeature(current_feature)

              if !f
                exitcode = 1
                $stderr.puts("error:  can't find feature #{f}")
                next
              end

              display_feature(f)

              if @transitive
                new_features = (f.included_features + f.depends).uniq.reject {|new_f| seen.include? new_f}

                new_features.each do |new_f|
                  seen << new_f
                  worklist << new_f
                end
              end
            end

            puts "]}" if @json

            return exitcode
          end

          def display_feature(f)
            puts "==="
            puts "Name: #{f.name}"
            [["Included features", f.included_features],
             ["Feature dependencies", f.depends],
             ["Feature conflicts", f.conflicts]].each do |description, collection|
              next if collection.size == 0
              puts "#{description}:"
              collection.each {|nm| puts "  - #{nm}"}
            end
            
            if f.params.size > 0
              puts "Parameter settings:"
              f.params.each {|k,v| puts "    #{k}=#{v}"}
            end
          end

          module JSONFormatter
            LIST_VALUED_ACCESSORS = %w{included_features depends conflicts}
            def display_feature(f)
              hash = {"name"=>f.name, "params"=>f.params}
              LIST_VALUED_ACCESSORS.each do |lva|
                val = f.send(lva)
                val ||= []
                val = [val] unless val.is_a?(Array)
                hash[lva] = val
              end

              puts hash.to_json, ","
            end

            def self.included(base)
              if ::String.methods.grep("to_json") == []
                ::String.class_eval do
                  def to_json
                    self.inspect
                  end
                end
              end

              if ::Array.methods.grep("to_json") == []
                ::Array.class_eval do
                  def to_json
                    "[#{self.map {|elt| elt.to_json}.join(", ")}]"
                  end
                end
              end

              if ::Hash.methods.grep("to_json") == []
                ::Hash.class_eval do
                  def to_json
                    pairs = self.map {|k,v| "#{k.to_json}: #{v.to_json}"}.join(",\n")
                    "{\n#{pairs}\n}"
                  end
                end
              end

            end
          end
          
          def post_arg_callback(*args)
            @args = args.dup
            if @json
              class << self
                include JSONFormatter
              end
            end 
          end

          register_callback :after_option_parsing, :post_arg_callback
        end
      end
    end
  end
end
