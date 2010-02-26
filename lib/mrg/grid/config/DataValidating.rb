module Mrg
  module Grid
    module Config
      module DataValidating
        module ClassMixins
          def select_invalid(args)
            args.reject {|name| self.find_first_by_name(name)}
          end
        end

        def self.included(receiver)
          class << receiver
            include ClassMixins
          end
        end
      end
    end
  end
end