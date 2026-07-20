RSpec.describe Compony::MethodAccessibleHash do
  it 'symbolizes keys given in the constructor' do
    hash = described_class.new('foo' => 1, bar: 2)
    expect(hash[:foo]).to eq(1)
    expect(hash[:bar]).to eq(2)
  end

  it 'provides read access via methods' do
    hash = described_class.new(foo: :bar)
    expect(hash.foo).to eq(:bar)
  end

  it 'returns nil for missing keys' do
    expect(described_class.new.anything).to be_nil
  end

  it 'provides write access via methods' do
    hash = described_class.new
    hash.foo = 42
    expect(hash[:foo]).to eq(42)
  end

  it 'responds to any method' do
    expect(described_class.new).to respond_to(:whatever)
  end

  it 'symbolizes keys on merge' do
    merged = described_class.new(foo: 1).merge('bar' => 2)
    expect(merged[:bar]).to eq(2)
    expect(merged['bar']).to be_nil
  end
end
