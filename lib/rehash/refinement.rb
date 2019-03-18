module Rehash
  refine Hash do
    def rehash(opts_or_mapping = {}, &block)
      ::Rehash.rehash(self, opts_or_mapping, &block)
    end
  end
end