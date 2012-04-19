# file.rb: file-related utilities
#
# Copyright (c) 2010 Red Hat, Inc.
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

require 'openssl'
require 'digest/sha1'
require 'pathname'

module Mrg
  module Grid
    module Util
      module File
        # resolves symbolic links and "."/".." in a path that *mostly* exists,
	# where a "mostly-existing" path is defined as one in which at most
	# the rightmost component does not exist.
	def path_resolve(p)
	  path = Pathname.new(p)

	  # we can realpath existing files
	  if path.exist?
	    return path.realpath.to_s
	  end

	  # we're creating a new file here.  the dir must exist, but the file will not
	  dirname = path.dirname.realpath rescue (raise "Directory #{path.dirname.to_s} does not exist")
	  (dirname + path.basename).to_s
	end

        def unique_name(template_name, tagprefix='', taglength=12, randsize=64) 
	  done_yet = false
	  result = nil

	  while not done_yet
            tag = Digest::SHA1.hexdigest(OpenSSL::Random.random_bytes(randsize)).slice(0,taglength)

	    dirname, basename = ::File.split(template_name)
	    basename_parts = basename.split(".")
	    basename_parts.insert(basename_parts.length < 2 ? -1 : -2, "#{tagprefix}#{tag}")
	    
	    result = ::File.join(dirname, basename_parts.join("."))
	    done_yet = true unless ::File.exist?(result)
	  end
	  result
	end
      end
    end
  end
end