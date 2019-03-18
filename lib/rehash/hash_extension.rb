module Rehash
  module HashExtension
    def rehash(opts_or_mapping = {}, &block)
      ::Rehash.rehash(self, opts_or_mapping, &block)
    end
  end
end