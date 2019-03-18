module Rehash
  class Rehasher
    attr_reader :result

    def initialize(hash, opts = Rehash.default_options)
      @hash = hash
      @result = {}
      @symbolize_keys = opts[:symbolize_keys]
      @delimiter = opts[:delimiter]
    end

    def call(mapping, &block)
      mapping.each do |from, to|
        value = get_value(from)
        value = yield value if block_given?
        put_value(to, value)
      end

      result
    end

    private

    def get_value(key)
      key.split(@delimiter).reject(&:empty?).reduce(@hash) do |result, part|
        return if !result
        result[part] || result[part.to_sym]
      end
    end

    def put_value(key, value)
      parts = key.split(@delimiter).reject(&:empty?)
      parts.each_with_index.reduce(@result) do |res, (part, i)|
        part_key = @symbolize_keys ? part.to_sym : part
        if i == parts.length - 1
          res[part_key] = value
        else
          res[part_key] = {}
        end
      end
    end
  end
end