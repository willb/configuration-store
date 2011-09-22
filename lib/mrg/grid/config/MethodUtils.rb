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
      def gen_setter(get)
        type = self.send(get).class
        tmp = get.split('_')
        cap_str = ""
        tmp.each do |w|
          cap_str += w.capitalize
        end
        if (type == Array) || (type == Hash)
          "modify#{cap_str}".intern
        else
          "set#{cap_str}".intern
        end
      end

      def gen_getter(set)
        set =~ /^set(.+)/
        if $1 == nil
          set =~ /^modify(.+)/
        end
        getter = $1.gsub(/([A-Z][a-z]*)/, '\1_').chop
        getter.downcase.intern
      end
    end

    module NameUtils
      def obj_type(attr)
        a = attr.to_s.gsub(/(.+)s/, '\1').capitalize
        if Mrg::Grid::Config.constants.include?(a)
          Mrg::Grid::Config.const_get(a).to_s.split("::").last.intern
        else
          options = Mrg::Grid::Config.constants.grep(/^#{a}/)
          type = ""
          options.each do |str|
            caps = 0
            str.chars{|c| caps += 1 if c =~ /[A-Z]/}
            if caps == 1
              type = str
            end
          end
          type.intern
        end
      end
    end
  end
end
