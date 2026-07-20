RSpec.describe Compony::Intent do
  let(:user) { User.create!(name: 'Alice') }
  let(:admin) { User.create!(name: 'Root', admin: true) }

  describe 'component resolution' do
    it 'resolves from comp and family' do
      expect(described_class.new(:show, :users).comp_class).to eq(Components::Users::Show)
    end

    it 'resolves from a model' do
      expect(described_class.new(:show, user).comp_class).to eq(Components::Users::Show)
    end

    it 'accepts a component class directly' do
      expect(described_class.new(Components::Users::Show).comp_class).to eq(Components::Users::Show)
    end

    it 'fails when neither component nor name/label are given' do
      expect { described_class.new }.to raise_error(RuntimeError, /must be given the kwargs/)
    end

    it 'allows a component-less intent with name and label' do
      intent = described_class.new(name: :external, label: 'External', path: 'https://example.com')
      expect(intent.comp_class).to be_nil
      expect(intent.name).to eq(:external)
      expect(intent.label).to eq('External')
      expect(intent.path).to eq('https://example.com')
    end
  end

  describe '#model?' do
    it 'is true for a record' do
      expect(described_class.new(:show, user).model?).to be(true)
    end

    it 'is false for a family symbol' do
      expect(described_class.new(:index, :users).model?).to be(false)
    end
  end

  describe '#path' do
    it 'builds the path from the model' do
      expect(described_class.new(:show, user).path).to eq("/users/show/#{user.id}")
    end

    it 'prefers an explicitly given path string' do
      expect(described_class.new(:show, user, path: '/custom').path).to eq('/custom')
    end
  end

  describe '#name' do
    it 'joins comp and family name' do
      expect(described_class.new(:show, :users).name).to eq(:show_users)
    end
  end

  describe '#method' do
    it 'defaults to :get' do
      expect(described_class.new(:show, user).method).to eq(:get)
    end

    it 'can be overridden' do
      expect(described_class.new(:destroy, user, method: :delete).method).to eq(:delete)
    end
  end

  describe 'feasibility' do
    it 'is feasible for allowed actions' do
      expect(described_class.new(:destroy, user).feasible?).to be(true)
    end

    it 'is infeasible when the model prevents the action' do
      expect(described_class.new(:destroy, admin).feasible?).to be(false)
    end

    it 'is feasible when no model is involved' do
      expect(described_class.new(:index, :users).feasible?).to be(true)
    end

    it 'disables the button when infeasible' do
      opts = described_class.new(:destroy, admin).button_comp_opts
      expect(opts[:href]).to be_nil
      expect(opts[:class]).to eq('disabled')
      expect(opts[:title]).to eq('Cannot destroy admins.')
    end

    it 'enables the button when feasible' do
      opts = described_class.new(:destroy, user).button_comp_opts
      expect(opts[:href]).to be_present
      expect(opts[:class]).to be_nil
      expect(opts[:title]).to be_nil
    end
  end
end
