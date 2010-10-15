#!/usr/bin/env ruby

# skel:  template wallaby-shell class
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
              
            end

          end
          
          def main(args)
            begin
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
            
            WallabyHttpServer.set :store, @store
            WallabyHttpServer.run! :port=>(@port || 4567)
            0
          end
          
        end

        class WallabyHttpServer < Sinatra::Base
          enable :lock, :dump_errors, :logging
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
