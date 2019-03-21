require "rehash/version"
require "rehash/rehasher"
require "rehash/hash_extension"
require "rehash/refinement"

module Rehash
  @@default_options = {delimiter: '/'.freeze, symbolize_keys: true}.freeze
  
  module_function

  def default_options(value = nil)
    return @@default_options if value.nil?

    @@default_options = @@default_options.merge(value).freeze
  end

  def map(hash, opts_or_mapping = {})
    if block_given?
      yield Rehasher.new(hash, default_options.merge(opts_or_mapping))
    else
      Rehasher.new(hash).(opts_or_mapping)
    end
  end
end
