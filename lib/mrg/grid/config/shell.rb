#!/usr/bin/env ruby

# shell:  wallaby shell commands
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

require 'qmf'
require 'optparse'
require 'timeout'

require 'mrg/grid/config-client'
require 'mrg/grid/config-proxies'

module Mrg
  module Grid
    module Config
      module Shell
        COMMANDS={}
        
        Args = Struct.new(:cmd, :for_wt, :for_cmd)

        def self.preprocess_args(args)
          result = Args.new
          pivot = 0

          args.each_with_index do |arg,idx|
            if (result.cmd = Mrg::Grid::Config::Shell::COMMANDS[arg]; result.cmd)
              pivot = idx
              break
            end
          end

          result.for_wt = args.slice(0,pivot)
          result.for_cmd = args.slice(pivot + 1, args.size)

          result
        end
        
        def self.main(args)
          host = ENV['WALLABY_BROKER_HOST'] || "localhost"
          port = (ENV['WALLABY_BROKER_PORT'] || 5672).to_i
          username = ENV['WALLABY_BROKER_USER']
          password = ENV['WALLABY_BROKER_PASSWORD']
          explicit_mechanism = ENV['WALLABY_BROKER_MECHANISM']
          debug = :warn

          op = OptionParser.new do |opts|
            opts.banner = "Usage:  wallaby [options] command [command-args]"

            opts.on("-h", "--help", "shows this message") do
              raise OptionParser::InvalidOption
            end

            opts.on("-H", "--host HOSTNAME", "qpid broker host (default localhost)") do |h|
              host = h
            end

            opts.on("-p", "--port NUM", "qpid broker port","   (default 5672)") do |num|
              port = num.to_i
            end

            opts.on("-U", "--user NAME", "qpid username") do |name|
              username = name
            end

            opts.on("-P", "--password PASS", "qpid password") do |pass|
              password = pass
            end

            opts.on("-M", "--auth-mechanism PASS", %w{ANONYMOUS PLAIN GSSAPI}, "authentication mechanism (#{%w{ANONYMOUS PLAIN GSSAPI}.join(", ")})") do |mechanism|
              explicit_mechanism = mechanism
            end
          end

          args = preprocess_args(args) unless args.is_a?(Args)

          unless args.cmd
            puts "fatal:  you must specify a command (#{Mrg::Grid::Config::Shell::COMMANDS.keys.join(", ")})"
            puts op
            exit
          end

          begin
            op.parse!(args.for_wt)
          rescue OptionParser::InvalidOption
            puts op
            exit
          rescue OptionParser::InvalidArgument => ia
            puts ia
            puts op
            exit
          end

          console = Qmf::Console.new

          settings = Qmf::ConnectionSettings.new
          settings.username = username if username
          settings.password = password if password
          settings.host = host
          settings.port = port

          implicit_mechanism = (username || password) ? "PLAIN" : "ANONYMOUS"
          settings.mechanism = explicit_mechanism || implicit_mechanism

          begin
            Timeout.timeout(15) do
              connection = Qmf::Connection.new(settings)

              broker = console.add_connection(connection)

              broker.wait_for_stable
            end
          rescue Timeout::Error
            puts "fatal:  timed out connecting to broker on #{host}:#{port}"
            exit!(1)
          end

          store = console.object(:class=>"Store")

          unless store
            puts "fatal:  cannot find a wallaby agent on the specified broker (#{host}:#{port}); is one running?"
            puts "use -h for help"
            exit!(1)
          end

          store_client = Mrg::Grid::ConfigClient::Store.new(store, console)

          args.cmd.new(store_client, "").main(args.for_cmd)
        end
      end
    end
  end
end

require 'mrg/grid/config/shell/add_param'
require 'mrg/grid/config/shell/snapshot'
require 'mrg/grid/config/shell/apropos'
