#!/usr/bin/env ruby

# http-server:  HTTP gateway to the wallaby agent
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

begin
  require 'rubygems'
  require 'sinatra/base'
  
  module Mrg
    module Grid
      module Config
        module Shell
          HTTP_SERVER_DEPS_OK = true
        end
      end
    end
  end
rescue LoadError
  module Mrg
    module Grid
      module Config
        module Shell
          HTTP_SERVER_DEPS_OK = false
        end
      end
    end
  end
end
  
module Mrg
  module Grid
    module Config
      module Shell
        class HttpServer
          def drop_privs(to_user=nil)
            to_user ||= "wallaby"
            if Process.euid == 0
              begin
                new_uid = Etc.getpwnam(to_user).uid
                new_gid = Etc.getpwnam(to_user).gid

                Process::Sys.setgid(new_gid)
                Process::Sys.setuid(new_uid)
              rescue ArgumentError
                Syslog.open do |s|
                  s.warning "can't switch to user #{to_user}; does it exist?"
                  puts  "can't switch to user #{to_user}; does it exist?"
                end
              end
            end
          end

          def daemonify
            pid = nil
            sid = nil

            return if Process.ppid == 1

            pid = fork

            if pid != nil
              if pid < 0
                Syslog.open {|s| s.fatal "can't fork child process"}
                exit!(1)
              end
              exit(0)
            end

            sid = Process.setsid
            if sid < 0
              Syslog.open {|s| s.fatal "can't set self as session group leader"}
              exit!(1)
            end

            exit!(1) if Dir.chdir("/") < 0

            # close open FDs
            $stdin.reopen("/dev/null", "r")
            $stdout.reopen("/dev/null", "w")
            $stderr.reopen("/dev/null", "w")
          end
          
          def initialize(storeclient, name, op=:httpServer)

            @op = op
            @store = storeclient
            @name = name

            @options = {}
            @oparser = OptionParser.new do |opts|
              
              opname = "http-server"
              
              opts.banner = "Usage:  wallaby #{opname}\nProvides a HTTP service gateway to wallaby configurations."
                
              opts.on("-h", "--help", "displays this message") do
                puts @oparser
                exit
              end
              
              opts.on("-p", "--port NUM", Integer, "port to listen on") do |num|
                @port = num.to_i
              end
              
              opts.on("-q", "--quiet", "do not log HTTP requests to stderr") do
                @quiet = true
              end
              
              opts.on("--run-as USER", "unix user to execute wallaby-agent as") do |user|
                # NB:  Perhaps obviously, this only has an effect if we're running as root
                # Also, if we're running in the foreground, we'll run as the current user
                # unless a run-as user is explicitly specified
                @run_as = user
              end

              opts.on("-f", "--foreground", "run HTTP server in the foreground") do
                @do_daemonify = false
              end
              
            end

          end
          
          def main(args)
            begin
              @do_daemonify = true
              @run_as = nil
              
              @oparser.parse!(args)
              
            rescue OptionParser::InvalidOption
              puts @oparser
              return
            rescue OptionParser::InvalidArgument => ia
              puts ia
              puts @oparser
              return
            end
            
            act
          end
          
          def act(kwargs=nil)
            unless Mrg::Grid::Config::Shell::HTTP_SERVER_DEPS_OK
              puts "fatal:  'wallaby http-server' requires rubygems and sinatra to be installed"
              return 1
            end
            
            daemonify if @do_daemonify
            drop_privs(@run_as) if (@do_daemonify || @run_as)
            
            WallabyHttpServer.set :store, @store
            
            if @quiet
              WallabyHttpServer.disable :dump_errors, :logging
            else
              WallabyHttpServer.enable :dump_errors, :logging
            end
            
            WallabyHttpServer.run! :port=>(@port || 4567)
            0
          end
          
        end

        class WallabyHttpServer < Sinatra::Base
          enable :lock
          disable :public

          get %r{/config/([^/]+)/at/([0-9]+)/?} do |node,c_when|
            store = settings.store
            
            # puts "node is '#{node}'"
            # puts "c_when is '#{c_when}'"
            
            n = store.getNode(node)
            
            config = n.getConfig({"version"=>(c_when.to_i)})
            
            config.keys.sort.map do |k|
              "#{k} = #{config[k]}\n"
            end
          end
          
          get %r{/changes-to/([^/]+)/since/([0-9]+)/?} do |node,c_old|
            store = settings.store
            
            c_new = (1 << 61)
            
            # puts "node is '#{node}'"
            # puts "c_when is '#{c_when}'"
            
            n = store.getNode(node)
            
            diff = n.whatChanged(c_old, c_new)
            
            comments = ["# Changes in the configuration to #{node} since version #{c_old}:\n"]
            
            diff.params.each do |param|
              comments << "# + the value of #{param} has changed\n"
            end

            diff.affected.each do |subsys|
              comments << "# + subsystem #{subsys} is affected\n"
            end

            diff.restart.each do |subsys|
              comments << "# + subsystem #{subsys} must restart\n"
            end
            
            comments << "# Current configuration for #{node} follows:\n"
            
            config = n.getConfig({"version"=>(c_old.to_i)})
            
            config.keys.sort.map do |k|
              comments << "#{k} = #{config[k]}\n"
            end
            
            comments
          end
          
          get '/config/:node/?' do |node|
            store = settings.store
            n = store.getNode(node)
            config = n.getConfig("version"=>(1<<61))
            
            config.keys.sort.map do |k|
              "#{k} = #{config[k]}\n"
            end
          end

          get '/unactivated-config/:node/?' do |node|
            redirect "/current-config/#{node}/", 301
          end

          get '/current-config/:node/?' do |node|
            store = settings.store
            n = store.getNode(node)
            config = n.getConfig
            
            config.keys.sort.map do |k|
              "#{k} = #{config[k]}\n"
            end
          end

          get '/help/?' do
            <<-USAGE
The Wallaby HTTP server provides read-only access to node 
configurations.  It understands the following requests:

GET /config/$NODENAME/
    returns a configuration file with the last activated
    configuration for $NODENAME.

GET /config/$NODENAME/at/$VERSION/
    returns a configuration file with the latest configuration
    for $NODENAME that is not more recent than $VERSION.

GET /current-config/$NODENAME/
    returns a configuration file with the "current"
    configuration for $NODENAME, possibly reflecting changes
    made since the last activation.

GET /changes-to/$NODENAME/since/$VERSION/
    returns a configuration file for the last activated
    configuration for $NODENAME, including comments at the
    beginning indicating which parameters have changed since
    $VERSION and which subsystems are affected by these changes.

GET /help/
    returns this message
            USAGE
          end

        end

        Mrg::Grid::Config::Shell::COMMANDS['http-server'] = HttpServer
        
      end
    end
  end
end
