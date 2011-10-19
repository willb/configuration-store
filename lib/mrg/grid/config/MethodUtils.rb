# MethodUtils: Translate between method types
#
# Copyright (c) 2011 Red Hat, Inc.
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

require 'set'

module Mrg
  module Grid
    module MethodUtils
      module ClassMixins
        def set_from_get(get)
          if self.spqr_meta.mmethods.keys.include?(get)
            type = self.spqr_meta.mmethods[get].kind
          else
            self.spqr_meta.properties.each {|p| type = p.kind if p.name == get}
            if (type == nil) or (type == "")
              raise RuntimeError.new("Invalid get accessor '#{get}'")
            end
          end
          tmp = get.to_s.split('_')
          cap_str = ""
          tmp.each do |w|
            cap_str += w.capitalize
          end
          if (type == :list) || (type == :map)
            "modify#{cap_str}".to_sym
          else
            "set#{cap_str}".to_sym
          end
        end

        def get_from_set(set)
          set.to_s =~ /^set(.+)/
          if $1 == nil
            set.to_s =~ /^modify(.+)/
          end
          if $1 == nil
            raise RuntimeError.new("Invalid set accessor #{set.inspect}")
          end
          getter = $1.gsub(/([A-Z][a-z]*)/, '\1_').chop
          getter.downcase.to_sym
        end
      end

      def self.included(receiver)
        receiver.extend ClassMixins
      end

      def self.attr_to_class(attr)
        a = attr.to_s.gsub(/(.+)s/, '\1').capitalize
        if Mrg::Grid::Config.constants.include?(a)
          Mrg::Grid::Config.const_get(a).to_s.split("::").last.to_sym
        else
          Mrg::Grid::Config.constants.grep(/^#{a}/).select {|x| Mrg::Grid::Config.const_get(x).ancestors.include?(::SPQR::Manageable) }[0].to_sym
        end
      end

      def self.find_method(sn, type="Store")
        Mrg::Grid::Config.const_get(type).spqr_meta.manageable_methods.map {|m| m.name.to_s}.grep(/#{sn}/)
      end

      def self.find_property(sn, type="Store")
        Mrg::Grid::Config.const_get(type).spqr_meta.properties.map {|p| p.name.to_s}.grep(/#{sn}/)
      end

      def self.find_store_method(regex)
        method = nil
        possibles = Mrg::Grid::MethodUtils.find_method(regex, "Store")
        if possibles.size == 1
          method = possibles[0]
        else
          possibles.each {|m| method = m if m =~ /^#{regex}[^A-Z]*ByName$/}
          possibles.each {|m| method = m if m =~ /^#{regex}$/} if method == nil
          possibles.each {|m| method = m if m =~ /^#{regex}[^A-Z]*$/} if method == nil
        end
        method
      end
    end
  end
end
