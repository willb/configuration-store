# ArcUtils.rb:  mixins for dealing with entity arcs
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
      module ArcUtils
        
        # * command is the "modify" command passed in from the tool
        # * dests is the set of keys for the input set
        # * options are provided by the tool
        # * getmsg is the message to get the current set of arcs
        # * setmsg is the message to set the current set of arcs
        # * keyword arguments include
        # ** =:explain= is a string describing the relationship modeled by the arc (for error messages)
        # ** =:keymsg= is the message to get the key value from self
        # ** =:preserve_order= is true if these arcs represent a list
        # ** =:xc= is a message to get the transitive closure of this relation from self
        def modify_arcs(command,dests,options,getmsg,setmsg,kwargs=nil)
          # NB:  this must work for lists and sets; note the ADD/UNION case
          
          dests = dests.keys if dests.is_a? Hash
          
          kwargs ||= {}
          
          explain = kwargs[:explain] || "have an arc to"
          what = kwargs[:what] || self.class.name.split("::").pop.downcase
          errwhat = Errors.const_get(what.upcase) || Errors::UNKNOWN
          keymsg = kwargs[:name] || :name
          preserve_order = kwargs[:preserve_order]
          xcmsg = kwargs[:xc]
          command = command.upcase
          
          if xcmsg and %w{ADD UNION REPLACE}.include? command then
            fail(Errors.make(Errors::CIRCULAR_RELATIONSHIP, errwhat), "Including #{what}s #{dests.inspect} in #{self.send(keymsg)} would introduce a cycle") if self.send(xcmsg, dests).include? self.send(keymsg)
          end
          
          case command
          when "ADD" then 
            old_dests = preserve_order ? self.send(getmsg) : Set[*self.send(getmsg)]
            new_dests = preserve_order ? dests : Set[*dests]
            fail(Errors.make(Errors::CIRCULAR_RELATIONSHIP, Errors::INVALID_RELATIONSHIP, errwhat), "#{what} #{name} cannot #{explain} itself") if new_dests.include? self.send(keymsg)
            self.send(setmsg, (old_dests + new_dests).to_a.uniq) # the uniq is important so this can work either as a list or set
          when "REPLACE" then 
            new_dests = preserve_order ? dests : Set[*dests]
            fail(Errors.make(Errors::CIRCULAR_RELATIONSHIP, Errors::INVALID_RELATIONSHIP, errwhat), "#{what} #{name} cannot #{explain} itself") if new_dests.include? self.send(keymsg)
            self.send(setmsg, new_dests.to_a)
          when "REMOVE" then
            old_dests = self.send(getmsg)
            removed_dests = dests
            new_dests = old_dests - removed_dests
            self.send(setmsg, new_dests)
          when "INTERSECT", "DIFF", "UNION" then
            fail(Errors.make(Errors::INTERNAL_ERROR, Errors::NOT_IMPLEMENTED, errwhat), "#{command} not implemented for order-preserving relations") if preserve_order
            old_dests = Set[*self.send(getmsg)]
            supplied_dests = Set[*dests]
            new_dests = ArcUtils.send("#{command.downcase}_collections", old_dests, supplied_dests).to_a
            fail(Errors.make(Errors::CIRCULAR_RELATIONSHIP, Errors::INVALID_RELATIONSHIP, errwhat), "#{what} #{name} cannot #{explain} itself") if new_dests.include? self.send(keymsg)
            self.send(setmsg, new_dests)
          else fail(Errors.make(Errors::BAD_COMMAND, errwhat), "Invalid command #{command}")
          end
        end
        
        def self.intersect_collections(first, second)
          first & second
        end

        def self.union_collections(first, second)
          first | second
        end
        
        def self.diff_collections(first, second)
          (first | second) - (first & second)
        end
        
        def find_arcs(arc_class,label)
          arc_class.find_by(:source=>self, :label=>label).map do |arc|
            if block_given? 
              yield arc 
            else
              arc
            end
          end
        end
        
        def set_arcs(arc_class, label, dests, keyfindmsg, options=nil)
          options ||= {}
          klass = (options[:klass] or self.class)
          what = (options[:what] or klass.name.split("::").pop.downcase)
          errwhat = Errors.const_get(what.upcase) || Errors::UNKNOWN
          dests = Set[*dests] unless options[:preserve_ordering]
          
          target_params = dests.map do |key|
            dest = klass.send(keyfindmsg, key)
            fail(Errors.make(Errors::NONEXISTENT_ENTITY, errwhat), "#{key} is not a valid #{what} key") unless dest
            dest
          end
          
          arc_class.find_by(:source=>self, :label=>label).map {|p| p.delete }
          
          target_params.each do |dest|
            arc_class.create(:source=>self.row_id, :dest=>dest.row_id, :label=>label.row_id)
          end
          
          dests.to_a
        end
        
      end
    end
  end
end