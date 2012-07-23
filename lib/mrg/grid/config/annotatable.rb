# annotatable.rb:  annotation/description metadata for entities
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
      module Annotatable
        MAX_ANNOTATION_LENGTH = 8192
        
        def setAnnotation(desc)
          desc ||= ""
          fail(Errors.make(Errors::BAD_ARGUMENT, Errors::ARGUMENT_TOO_LONG, (Errors.const_get(self.class.cbasename.upcase) || 0)), "#{self.class.cbasename} annotation is too long; must be under #{MAX_ANNOTATION_LENGTH} characters.") unless desc.size < MAX_ANNOTATION_LENGTH
          @__annotation_dirtymsg ||= "dirty_#{self.class.cbasename.downcase}"
          self.annotation = desc
          DirtyElement.send(@__annotation_dirtymsg, self) if DirtyElement.respond_to?(@__annotation_dirtymsg)
        end
        
        module ClassMixins
          def cbasename
            self.class.name.split("::").pop
          end
        end

        def self.included(receiver)
          class << receiver
            include ClassMixins
          end

          receiver.declare_column :annotation, :text
          receiver.qmf_property :annotation, :lstr, :description=>"a user-defined annotation for this property; introduced in API version 20101031.4"
          
          receiver.expose :setAnnotation do |args|
            args.declare :name, :sstr, :in, "An updated annotation for this #{self.class.name.split("::").pop.downcase}.  This method was introduced in API version 20101031.4."
          end
          
          receiver.authorize_before(:annotation, :READ) rescue log.warn "FIXME:  Annotatable included before Auth::ORIZING"
          receiver.authorize_before(:setAnnotation, :WRITE) rescue log.warn "FIXME:  Annotatable included before Auth::ORIZING"
          
        end
      end
    end
  end
end