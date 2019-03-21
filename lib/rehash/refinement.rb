module Rehash
  refine Hash do
    def map_with(opts_or_mapping = {}, &block)
      ::Rehash.map(self, opts_or_mapping, &block)
    end
  end
end
