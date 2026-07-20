RSpec.describe Compony::NaturalOrdering do
  subject(:collection) { described_class.new }

  it 'appends elements in order' do
    collection.natural_push(:a, 1)
    collection.natural_push(:b, 2)
    expect(collection.map(&:name)).to eq(%i[a b])
    expect(collection.map(&:payload)).to eq([1, 2])
  end

  it 'inserts before a given element' do
    collection.natural_push(:a, 1)
    collection.natural_push(:c, 3)
    collection.natural_push(:b, 2, before: :c)
    expect(collection.map(&:name)).to eq(%i[a b c])
  end

  it 'overwrites an existing element in place' do
    collection.natural_push(:a, 1)
    collection.natural_push(:b, 2)
    collection.natural_push(:a, 99)
    expect(collection.map(&:name)).to eq(%i[a b])
    expect(collection.first.payload).to eq(99)
  end

  it 'keeps old kwargs when overwriting without specifying them' do
    collection.natural_push(:a, 1, hidden: true)
    collection.natural_push(:a, 2)
    expect(collection.first.hidden).to be(true)
    expect(collection.first.payload).to eq(2)
  end

  it 'allows omitting the payload when overwriting' do
    collection.natural_push(:a, 1)
    collection.natural_push(:a, hidden: true)
    expect(collection.first.payload).to eq(1)
    expect(collection.first.hidden).to be(true)
  end

  it 'moves an existing element when overwriting with before:' do
    collection.natural_push(:a, 1)
    collection.natural_push(:b, 2)
    collection.natural_push(:c, 3)
    collection.natural_push(:c, 3, before: :a)
    expect(collection.map(&:name)).to eq(%i[c a b])
  end

  it 'fails when inserting a new element without payload' do
    expect { collection.natural_push(:a) }.to raise_error(RuntimeError, /without a payload/)
  end

  it 'fails when before: refers to a missing element' do
    collection.natural_push(:a, 1)
    expect { collection.natural_push(:b, 2, before: :nope) }.to raise_error(RuntimeError, /not found/)
  end

  it 'stores extra kwargs on the element' do
    collection.natural_push(:a, 1, hidden: true)
    expect(collection.select(&:hidden).map(&:name)).to eq([:a])
  end
end
