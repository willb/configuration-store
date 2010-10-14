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
          
          get '/config/:node/?' do |node|
            store = settings.store
            n = store.getNode(node)
            config = n.getConfig("version"=>(1<<61))
            
            config.keys.sort.map do |k|
              "#{k} = #{config[k]}\n"
            end
          end

          get '/unactivated-config/:node/?' do |node|
            store = settings.store
            n = store.getNode(node)
            config = n.getConfig
            
            config.keys.sort.map do |k|
              "#{k} = #{config[k]}\n"
            end
          end

        end

        Mrg::Grid::Config::Shell::COMMANDS['http-server'] = HttpServer
        
      end
    end
  end
end
