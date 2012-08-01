# auth.rb:  user and authorization subsystem for Wallaby
#
# Copyright (c) 2012 Red Hat, Inc.
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

require 'mrg/grid/config'

module Mrg
  module Grid
    module Config
      module Auth
        module Priv
          NONE = 0
          
          READ_ONLY = 1
          WRITE_ONLY = 1 << 1
          ACTIVATE_ONLY = 1 << 2
          
          READ = READ_ONLY
          WRITE = WRITE_ONLY | READ_ONLY
          ACTIVATE = ACTIVATE_ONLY
          ADMIN = READ | WRITE | ACTIVATE
          
          def self.to_string(priv)
            @PRIVS ||= Mrg::Grid::Config::Auth::Priv.constants.inject({}) {|acc, val| acc[Mrg::Grid::Config::Auth::Priv.const_get(val)] = val; acc}
            @PRIVS[priv] || "NONE"
          end
        end
        
        module RoleCache
          def self.populate(fixture=nil)
            @cache = {}
            (fixture || ::Mrg::Grid::Config::Auth::Role.find_all).each do |r|
              @cache[r.username] = r.privs
            end
          end
          
          def self.authorized_to(verb, user)
            priv = ::Mrg::Grid::Config::Auth::Priv.const_get(verb)
            $WALLABY_SKIP_AUTH || cache.empty? || (cache[user].to_i & priv == priv) || (cache["*"].to_i & priv == priv)
          end
          
          def self.cache
            @cache ||= self.populate
          end
        end
        
        # Currently authentication is handled by the messaging broker.  
        # Role maps from a list of user names to privilege levels.  Note 
        # that it is not exposed over the API.  This class manages persistently-
        # stored Role mappings.
        class Role
          include ::Rhubarb::Persisting
          
          declare_column :username, :string, :not_null
          declare_column :privs, :integer, :not_null
        end
        
        module ORIZING
          module CM
            def authorize_before(method, action)
              orig_method = "UNCHECKED__#{method}".to_sym
              alias_method orig_method, method
              define_method(method) do |*args|
                unless ::Mrg::Grid::Config::Auth::RoleCache.authorized_to(action, qmf_user_id)
                  fail(::Mrg::Grid::Config::Errors.make(::Mrg::Grid::Config::Errors::UNAUTHORIZED), "'#{qmf_user_id}' does not have #{action} access and cannot invoke #{method}")
                end
                self.send(orig_method, *args)
              end
            end
          end
          
          module IM
            def authorize_now(action)
              unless ::Mrg::Grid::Config::Auth::RoleCache.authorized_to(action, qmf_user_id)
                fail(::Mrg::Grid::Config::Errors.make(::Mrg::Grid::Config::Errors::UNAUTHORIZED), "'#{qmf_user_id}' does not have #{action} access and cannot invoke #{self.class.name}##{caller[0][/`.*'/][1..-2]}")
              end
            end
            
            def authorized_via_secret(secret)
              (secret && $WALLABY_SECRET && secret == $WALLABY_SECRET)
            end
          end
          
          def self.included(receiver)
            receiver.extend CM
            receiver.include IM
          end
        end        
      end
    end
  end
end