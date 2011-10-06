# version:  version metadata
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
      module Version
        MAJOR=0
        MINOR=11
        PATCH=1
        BUILD=nil
        
        def self.as_string
          BUILD ? "#{MAJOR}.#{MINOR}.#{PATCH}.#{BUILD}" : "#{MAJOR}.#{MINOR}.#{PATCH}"
        end
      end
    end
  end
end
