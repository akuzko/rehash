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

    def get_value(path)
      path.split(@delimiter).reject(&:empty?).reduce(@hash) do |result, key|
        return if !result

        with_array_access, array_key, index = with_array_access?(key)
        
        if with_array_access
          lookup(result[array_key] || result[array_key.to_sym], index)
        else
          result[key] || result[key.to_sym]
        end
      end
    end

    def put_value(path, value)
      keys = path.split(@delimiter).reject(&:empty?)
      keys.each_with_index.reduce(@result) do |res, (key, i)|
        result_key = @symbolize_keys ? key.to_sym : key
        if i == keys.length - 1
          res[result_key] = value
        else
          res[result_key] = {}
        end
      end
    end

    def with_array_access?(key)
      return key =~ /^([^\[\]]+)\[([\d\w_:-]+)\]$/, $1, $2
    end

    def lookup(array, index)
      return array[index.to_i] unless index =~ /^([^:]+):(.+)$/
      
      key, value = $1, $2
      array.find { |item| (item[key] || item[key.to_sym]) == value }
    end
  end
end
