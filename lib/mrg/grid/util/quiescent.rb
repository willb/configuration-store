# Quiescing constants for Ruby.
#
# Copyright (c) 2011 Red Hat, Inc.
#
# Author:  William Benton (willb@redhat.com)
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0

module Mrg
  module Grid
    module Util
      module Quiescent
        module CM
          def quiescent(name, value=nil, &blk)
            name = name.to_s
            fail NameError.new("Invalid constant name '#{name}'") unless name =~ /^[A-Z]\w*$/
            blk ||= lambda {value}
            __qcs[name.to_sym] = blk
            self
          end

          def __qcs
            @__qcs ||= {}
          end

          def quiesce(name, val)
            if __qcs[name]
              const_set(name, val)
              __qcs.delete(name)
              return val
            end
            return nil
          end

          def const_missing(name)
            name = name.to_sym
            if __qcs[name]
              quiesce(name, __qcs[name].call)
            else
              super
            end
          end

          def method_missing(m, *args, &blk)
            if m.to_s =~ /^([A-Z]\w*?)=$/ && __qcs[$1.to_sym]
              quiesce($1.to_sym, *args)
            else
              super
            end
          end
        end

        def self.included(receiver)
          receiver.extend CM
          receiver.send(:private_class_method, :__qcs)
          receiver.send(:private_class_method, :quiescent)
        end
      end
    end
  end
end
