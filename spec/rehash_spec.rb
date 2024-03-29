require 'spec_helper'
require 'pry'

describe Rehash do
  it 'has a version number' do
    expect(Rehash::VERSION).not_to be nil
  end

  describe '#rehash' do
    let(:hash) do
      {
        foo: {
          bar: {
            baz: 1
          }
        },
        other_foo: 2,
        foos: [
          { bar: { baz: '3-1' } },
          { bar: { baz: '3-2' } },
          { bar: { baz: '3-3' } }
        ],
        config: [
          { name: 'important_value', value: 'yes' },
          { name: 'secondary_value', value: 'no' }
        ],
        big_foo: {
          nested: {
            bar1: { baz: '4-1' },
            bar2: { baz: '4-2' },
            bar3: { baz: '4-3' }
          }
        },
        'falsy_foo' => false
      }
    end

    describe 'usage' do
      it 'transforms hash using specified mapping' do
        result = Rehash.map(hash,
          '/foo/bar/baz' => '/foo/baz',
          '/other_foo'   => '/ofoo'
        )

        expect(result).to eq(ofoo: 2, foo: {baz: 1})
      end

      it 'preserves boolean values' do
        result = Rehash.map(hash, '/falsy_foo' => '/is_foo')

        expect(result).to eq(is_foo: false)
      end

      describe 'block form' do
        it 'transforms hash yielding a callable mapper object' do
          result = Rehash.map(hash) do |m|
            m.(
              '/foo/bar/baz' => '/foo/baz',
              '/other_foo'   => '/ofoo',
              '/falsy_foo' => '/is_foo'
            )
          end

          expect(result).to eq(ofoo: 2, is_foo: false, foo: {baz: 1})
        end

        describe 'yielding mapped value' do
          it 'yields a value to a block' do
            result = Rehash.map(hash) do |m|
              m.('/foos' => '/foos') do |foos|
                foos.map do |item|
                  Rehash.map(item, '/bar/baz' => '/value')
                end
              end
            end

            expect(result).to eq(foos: [{value: '3-1'}, {value: '3-2'}, {value: '3-3'}])
          end

          context 'when more than one path is specified' do
            it 'yields all mapped values' do
              result = Rehash.map(hash) do |m|
                m.('/foo/bar/baz' => '/foo/baz', '/other_foo' => '/ofoo') do |val|
                  val * 2
                end
              end

              expect(result).to eq(ofoo: 4, foo: {baz: 2})
            end
          end
        end
      end

      describe 'array access' do
        specify 'by index' do
          expect(Rehash.map(hash, '/foos[1]/bar/baz' => '/second_foo'))
            .to eq(second_foo: '3-2')
        end

        specify 'by index with negative value' do
          expect(Rehash.map(hash, '/foos[-1]/bar/baz' => '/last_foo'))
            .to eq(last_foo: '3-3')
        end

        specify 'by property lookup' do
          expect(Rehash.map(hash, '/config[name:important_value]/value' => '/important'))
            .to eq(important: 'yes')
        end
      end

      describe ':default option' do
        it 'uses default value only if not found or nil' do
          result = Rehash.map(hash) do |m|
            m.('/foo/bar/baz' => '/faz', '/foo/bar/bak' => '/fak', default: 2)
          end

          expect(result).to eq(faz: 1, fak: 2)
        end
      end
    end

    describe 'helper methods' do
      describe '#map_array' do
        it 'maps array (any enum, actually) value yielding mapper instances' do
          result = Rehash.map(hash) do |m|
            m.map_array('/foos' => '/foos') do |im|
              im.('/bar/baz' => '/value')
            end
          end

          expect(result).to eq(foos: [{value: '3-1'}, {value: '3-2'}, {value: '3-3'}])
        end
      end

      describe '#map_hash' do
        it 'maps hash value yielding mapper instance' do
          result = Rehash.map(hash) do |m|
            m.map_hash('/big_foo/nested' => '/') do |hm|
              hm.(
                '/bar1/baz' => '/big_baz1',
                '/bar2/baz' => '/big_baz2',
                '/bar3/baz' => '/big_baz3'
              )
            end
          end

          expect(result).to eq(big_baz1: '4-1', big_baz2: '4-2', big_baz3: '4-3')
        end
      end

      describe '#[] and #[]=' do
        it 'reads value from source and puts value to the result' do
          result = Rehash.map(hash) do |m|
            m['/foo'] = m['/foo/bar/baz']
          end

          expect(result).to eq(foo: 1)
        end
      end
    end

    describe ':symbolize_keys option' do
      context 'when `false` value is passed' do
        it 'results in string keys' do
          result = Rehash.map(hash, symbolize_keys: false) do |m|
            m.(
              '/foo/bar/baz' => '/foo/baz',
              '/other_foo'   => '/ofoo'
            )
          end

          expect(result).to eq('ofoo' => 2, 'foo' => {'baz' => 1})
        end
      end
    end

    describe ':delimiter option' do
      it 'uses specified delimiter to split path' do
        result = Rehash.map(hash, delimiter: '.') do |m|
          m.(
            'foo.bar.baz' => 'foo.baz',
            'other_foo'   => 'ofoo'
          )
        end

        expect(result).to eq(ofoo: 2, foo: {baz: 1})
      end
    end

    describe 'HashExtension' do
      let(:hash) { super().dup.extend(Rehash::HashExtension) }

      specify 'basic usage' do
        expect(hash.map_with('/foo/bar/baz' => '/foo'))
          .to eq(foo: 1)
      end

      specify 'with options and block form' do
        result = hash.map_with(delimiter: '.') do |m|
          m.('foo.bar.baz' => 'foo') { |v| v * 2 }
        end

        expect(result).to eq(foo: 2)
      end
    end

    describe 'Refinement' do
      using Rehash

      specify 'basic usage' do
        expect(hash.map_with('/foo/bar/baz' => '/foo')).to eq(foo: 1)
      end

      specify 'with options and block form' do
        result = hash.map_with(delimiter: '.') do |m|
          m.('foo.bar.baz' => 'foo') { |v| v * 2 }
        end

        expect(result).to eq(foo: 2)
      end
    end
  end
end
