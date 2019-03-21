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
          { bar: { baz: '3-2' } }
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
        }
      }
    end

    describe 'usage' do
      it 'transforms hash using specified mapping' do
        result =
          Rehash.rehash(hash,
            '/foo/bar/baz' => '/foo/baz',
            '/other_foo'   => '/ofoo'
          )

        expect(result).to eq(ofoo: 2, foo: {baz: 1})
      end

      describe 'block form' do
        it 'transforms hash yielding a callable rehasher object' do
          result =
            Rehash.rehash(hash) do |r|
              r.(
                '/foo/bar/baz' => '/foo/baz',
                '/other_foo'   => '/ofoo'
              )
            end

          expect(result).to eq(ofoo: 2, foo: {baz: 1})
        end

        describe 'yielding mapped value' do
          it 'yields a value to a block' do
            result =
              Rehash.rehash(hash) do |r|
                r.('/foos' => '/foos') do |foos|
                  foos.map do |item|
                    Rehash.rehash(item, '/bar/baz' => '/value')
                  end
                end
              end

            expect(result).to eq(foos: [{value: '3-1'}, {value: '3-2'}])
          end

          context 'when more than one path is specified' do
            it 'yields all mapped values' do
              result =
                Rehash.rehash(hash) do |r|
                  r.('/foo/bar/baz' => '/foo/baz', '/other_foo' => '/ofoo') do |val|
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
          expect(Rehash.rehash(hash, '/foos[1]/bar/baz' => '/last_foo'))
            .to eq(last_foo: '3-2')
        end

        specify 'by property lookup' do
          expect(Rehash.rehash(hash, '/config[name:important_value]/value' => '/important'))
            .to eq(important: 'yes')
        end
      end

      describe ':default option' do
        it 'uses default value only if not found or nil' do
          result = Rehash.rehash(hash) do |r|
            r.('/foo/bar/baz' => '/faz', '/foo/bar/bak' => '/fak', default: 2)
          end

          expect(result).to eq(faz: 1, fak: 2)
        end
      end
    end

    describe 'helper methods' do
      describe '#map' do
        it 'maps enum value yielding rehasher instances' do
          result =
            Rehash.rehash(hash) do |r|
              r.map('/foos' => '/foos') do |ire|
                ire.('/bar/baz' => '/value')
              end
            end

          expect(result).to eq(foos: [{value: '3-1'}, {value: '3-2'}])
        end
      end

      describe '#rehash' do
        it 'maps hash value yielding rehasher instance' do
          result =
            Rehash.rehash(hash) do |r|
              r.rehash('/big_foo/nested' => '/') do |hr|
                hr.(
                  '/bar1/baz' => '/big_baz1',
                  '/bar2/baz' => '/big_baz2',
                  '/bar3/baz' => '/big_baz3'
                )
              end
            end

          expect(result).to eq(big_baz1: '4-1', big_baz2: '4-2', big_baz3: '4-3')
        end
      end
    end

    describe ':symbolize_keys option' do
      context 'when `false` value is passed' do
        it 'results in string keys' do
          result =
            Rehash.rehash(hash, symbolize_keys: false) do |r|
              r.(
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
        result =
          Rehash.rehash(hash, delimiter: '.') do |r|
            r.(
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
        expect(hash.rehash('/foo/bar/baz' => '/foo'))
          .to eq(foo: 1)
      end

      specify 'with options and block form' do
        result = hash.rehash(delimiter: '.') do |r|
          r.('foo.bar.baz' => 'foo') { |v| v * 2 }
        end

        expect(result).to eq(foo: 2)
      end
    end

    describe 'Refinement' do
      using Rehash

      specify 'basic usage' do
        expect(hash.rehash('/foo/bar/baz' => '/foo'))
          .to eq(foo: 1)
      end

      specify 'with options and block form' do
        result = hash.rehash(delimiter: '.') do |r|
          r.('foo.bar.baz' => 'foo') { |v| v * 2 }
        end

        expect(result).to eq(foo: 2)
      end
    end
  end
end
