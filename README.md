# Rehash

This gem allows you to transform a hash from one structure to another. For instance,
to extract deeply nested values from it to a more convenient form with a simple and
easy-to use mapping. Inspired by [hash_mapper](https://github.com/ismasan/hash_mapper),
but has a more DRY and robust API.

Do not be confused with Ruby's core `Hash#rehash` method. This gem has nothing to
do with it and is used solely for mapping values from source hash into another one.

[![build status](https://secure.travis-ci.org/akuzko/rehash.png)](http://travis-ci.org/akuzko/rehash)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 're-hash', require: 'rehash'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install re-hash

## Usage

Considering we have a following hash:

```rb
hash = {
  foo: {
    bar: {
      baz: 1,
      bak: 2
    }
  },
  foos: [
    { bar: { baz: '3-1' } },
    { bar: { baz: '3-2' } }
  ],
  big_foo: {
    nested: {
      bar1: { baz: '4-1' },
      bar2: { baz: '4-2' },
      bar3: { baz: '4-3' }
    }
  },
  config: [
    {name: 'important_value', value: 'yes'},
    {name: 'secondary_value', value: 'no'}
  ]
}
```

### Simple mapping

Simple mapping, provided as a mapping hash, allows to quickly map source hash
values to new structure:

```rb
Rehash.map(hash,
  '/foo/bar/baz'             => '/faz',
  '/big_foo/nested/bar1/baz' => '/baz1'
)
# => {:faz => 1, :baz1 => '4-1'}
```

### Block usage

`Rehash.map` method yield a `Rehasher` instance that allows you to apply multiple
mappings, as well as transform mapped values themselves:

```rb
Rehash.map(hash) do |r|
  r.(
    '/foo/bar/baz' => '/faz',
    '/foo/bar/bak' => '/fak'
  )
  r.('/big_foo/nested/bar1/baz' => '/baz1') do |value|
    value.to_i
  end
  r.('/foos' => '/foos') do |foos|
    foos.map{ |item| Rehash.map(item, '/bar/baz' => '/value') }
  end
end
# => {:baz1 => 4, faz: 1, fak: 2, :foos => [{:value => '3-1'}, {:value => '3-2'}]}
```

Please note that **return value of the block is the return value of `.map` method call**,
so inside of this block you may do any kind of additional manipulations over resulting
object that can be accessed with `r.result` in example above

### Accessing array items

#### By index

It is very easy to map values from items within array by accessing them by index:

```rb
Rehash.map(hash, '/foos[0]/bar/baz' => '/first_faz')
# => {:first_faz => '3-1'}
```

#### By property lookup

It is also possible to access item within array by one of it's properties:

```rb
Rehash.map(hash, '/config[name:important_value]/value' => '/important')
# => {:important => 'yes'}
```

### Refinement (recommended usage)

`Rehash` also implements a `Hash` class refinement, using which is actually
**a recommended way** of using `re-hash`. Considering that `#map` and `#rehash`
methods are part of Ruby's Hash core functionality, `Rehash` allows to use
`#map_with` method for hash mappings.

```rb
using Rehash

hash.map_with('/foo/bar/baz' => '/faz') # => {:faz => 1}
# OR:
hash.map_with do |r|
  r.('/foo/bar/bak' => '/fak') { |v| v * 2 }
end
# => {:fak => 4}
```

### HashExtension

In case if you don't want to use refinement and want to have `#map_with` method
globally available, you can extend `Hash` itself with core extension:

```rb
Hash.send(:include, HashExtension)

{foo: 'baz'}.map_with('/foo' => '/bar') # => {bar: 'baz'}
```

### Options

`Rehash` uses `'/'` as path delimiter by default, as well as it symbolizes resulting
keys. To use other options on a distinct `map` or `map_with` calls you have to use block form:

```rb
Rehash.map(hash, delimiter: '.', symbolize_keys: false) do |r|
  r.('foo.bar.baz' => 'foo.baz')
)
# => {"foo" => {"baz" => 1}}
```

Or you can set default options globally:

```rb
Rehash.default_options(delimiter: '.', symbolize_keys: false)
Rehash.map(hash, 'foo.bar.baz' => 'foo.baz') # => {"foo" => {"baz" => 1}}
```

### Default value

On mapping, for convenience, you can use `default` option that will be assigned
to value that is missing at the specified path in the source hash or is `nil`
*before* it is yielded to the block (if block is given):

```rb
Rehash.map(hash) do |r|
  r.('/foo/bar/baz' => 'faz', '/missing' => '/bak', default: 5) do |value|
    value * 2
  end
end
# => {:faz => 2, :bar => 10}
```

### Helper methods

`Rehasher` instance that is yielded to the block also has a couple of small helper
methods for dealing with arrays and deeply nested values to make things even more DRY.

- `map(from => to, &block)` - used to map a collection at path `from` to a path `to`,
  yielding a `Rehasher` instance for each item:

```rb
Rehash.map(hash) do |r|
  r.map('/foos' => '/foos') do |ir|
    ir.('/bar/baz' => '/value')
  end
  # is the same as:
  r.('/foos' => '/foos') do |value|
    value.map do |item|
      Rehash.map(item, '/bar/baz' => '/value')
    end
  end
end
```

- `rehash(from => to, &block)` - yields a `Rehasher` instance for a hash located at
  the path `from` and puts result of rehashing to the path defined by `to`:

```rb
Rehash.map(hash) do |r|
  r.rehash('/big_foo/nested' => '/') do |hr|
    hr.(
      '/bar1/baz' => '/big_baz1',
      '/bar2/baz' => '/big_baz2',
      '/bar3/baz' => '/big_baz3'
    )
  end
  # is the same as:
  r.(
    '/big_foo/nested/bar1/baz' => '/big_baz1',
    '/big_foo/nested/bar2/baz' => '/big_baz2',
    '/big_foo/nested/bar3/baz' => '/big_baz3'
  )
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec`
to run the tests. You can also run `bin/console` for an interactive prompt that will allow
you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/akuzko/rehash.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

