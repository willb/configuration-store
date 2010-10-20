# cmd_new_command.rb:  generate a skeleton wallaby-shell command
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

require 'erb'
require 'enumerator'

module Mrg
  module Grid
    module Config
      module Shell
        class NewCommand < Command
          
          def self.opname
            "new-command"
          end
          
          def self.description
            "Generates a Ruby file containing a template for a new wallaby shell command."
          end
          
          def init_option_parser
            @initializer_callbacks = []
            @before_option_parsing_callbacks = []
            @after_option_parsing_callbacks = []
            @apache_license = true
            @module = "Mrg::Grid::Config::Shell"
            
            OptionParser.new do |opts|
              opts.banner = "Usage:  wallaby #{self.class.opname}\n#{self.class.description}."
              
              opts.on("-h", "--help", "displays this message") do
                puts @oparser
                exit
              end
              
              opts.on("-n", "--name NAME", "create a command named NAME") do |name|
                @cmd_name = name
              end
              
              opts.on("-d", "--description DESC", "supply a short description for this command") do |desc|
                @description = desc
              end
              
              opts.on("--suppress-license", "omits Apache license from generated files") do
                @apache_license = false
              end
              
              opts.on("-m", "--module MOD", "places the generated class in module MOD") do |name|
                @module = name
              end
              
              opts.on("--init-callback NAME", "declares an initializer callback method.") do |name|
                @initializer_callbacks << name
              end

              opts.on("--pre-args-callback NAME", "declares a callback to process arguments before option parsing.") do |name|
                @before_option_parsing_callbacks << name
              end
              
              opts.on("--post-args-callback NAME", "declares a callback method to process arguments after option parsing.") do |name|
                @after_option_parsing_callbacks << name
              end
            end
          end
          
          def validate_args(*args)
            unless @cmd_name
              exit!(1, "You must provide a name for the new command.  Use --help for help.")
            end
            
            @filename = "cmd_#{@cmd_name.gsub("-", "_")}.rb"
            @classname = @cmd_name.split("-").map {|part| part.capitalize}.join
            split_module = @module.split("::")
            @module_start = split_module.enum_with_index.map {|m,i| "#{"  " * i}module #{m}"}.join("\n")
            @module_end = split_module.enum_with_index.map {|m,i| "#{"  " * i}end"}.reverse.join("\n")
            @class_indent = "  " * (split_module.size)
          end

          register_callback :after_option_parsing, :validate_args
          
          def act
            # This method is responsible for actually performing the work of the command.  
            # It may read the @kwargs instance variable, which should be a hash, and must
            # return an integer, corresponding to the exit code of the command.
            puts render
            0
          end
          
          private
          def render
            @class_text = ERB.new(class_template_text, 0, '%<>').result(binding)
            ERB.new(file_template_text, 0, '%<>').result(binding)
          end
          
          def file_template_text
            <<-END
# <%= @filename %>:  <%= @description %>
<% if @apache_license %>
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
<% end %>

<%= @module_start %>

<% @class_text.each do |line| %><%= @class_indent %><%= line%><% end %>

<%= @module_end %>
            END
          end

          def class_template_text
            %q{class <%=@classname%> < ::Mrg::Grid::Config::Shell::Command
  # opname returns the operation name; for "wallaby foo", it
  # would return "foo".
  def self.opname
    "<%= @cmd_name %>"
  end

  # description returns a short description of this command, suitable 
  # for use in the output of "wallaby help commands".
  def self.description
    "<%= @description %>"
  end

  def init_option_parser
    # Edit this method to generate a method that parses your command-line options.
    OptionParser.new do |opts|
      opts.banner = "Usage:  wallaby #{self.class.opname}\n#{self.class.description}"

      opts.on("-h", "--help", "displays this message") do
        puts @oparser
        exit
      end
    end
  end
<% @initializer_callbacks.each_with_index do |callback,i| %>

  def <%= callback %>
<% if i == 0 %>
    # You can define multiple callback methods for each of several
    # events. <%= callback%> will be called at the end of the initializer.
<% else %>
    # <%= callback%> will be invoked at the end of the initializer.
<% end %>
  end

  register_callback :initialize, :<%= callback %>
<% end %>
<% @before_option_parsing_callbacks.each_with_index do |callback,i| %>

  def <%= callback%>(*args)
<% if i == 0 %>
    # <%= callback%> will be invoked before command-line argument
    # processing. args will contain every argument passed to this
    # command (before parsing, but after any changes made by prior
    # callbacks).
<% else %>
    # <%= callback%> will be invoked before command-line parsing.
<% end %>
  end

  register_callback :before_option_parsing, :<%= callback%>
<% end %>
<% @after_option_parsing_callbacks.each_with_index do |callback,i| %>

  def <%= callback%>(*args)
<% if i == 0 %>
    # <%= callback%> will be invoked after command-line argument
    # processing.  args will contain every argument passed to this
    # command (after any processed command-line options are removed),
    # minus any arguments removed by prior callbacks. It may include,
    # for example, input filenames.
<% else %>
    # <%= callback%> will be invoked after command-line parsing.
<% end %>
  end

  register_callback :after_option_parsing, :<%= callback%>
<% end %>

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

    return 0
  end
end}
          end
        end
      end
    end
  end
end
