RSpec.describe Compony::Component do
  describe 'naming' do
    it 'knows its comp and family name' do
      expect(Components::Users::Show.comp_name).to eq('show')
      expect(Components::Users::Show.family_name).to eq('users')
    end
  end

  describe 'labelling' do
    let(:user) { User.create!(name: 'Alice') }

    it 'returns the long label by default' do
      expect(Components::Users::Show.new.label(user)).to eq('Show user Alice')
    end

    it 'returns the short label on demand' do
      expect(Components::Users::Show.new.label(user, format: :short)).to eq('Show')
    end

    it 'applies label(:all) to both formats' do
      comp = Components::Users::Index.new
      expect(comp.label(format: :long)).to eq('Users')
      expect(comp.label(format: :short)).to eq('Users')
    end
  end

  describe 'setup inheritance' do
    it 'runs the parent setup before the child setup, letting children override' do
      parent = Class.new(Compony::Component) do
        setup do
          label(:all) { 'Parent' }
        end
      end
      child = Class.new(parent) do
        setup do
          label(:all) { 'Child' }
        end
      end
      stub_const('Components::Tests::Parent', parent)
      stub_const('Components::Tests::Child', child)
      expect(child.new.label).to eq('Child')
      expect(parent.new.label).to eq('Parent')
    end
  end

  describe 'standalone config' do
    it 'stores path and verbs' do
      config = Components::Users::Show.new.standalone_configs[nil] || Components::Users::Show.new.standalone_configs.values.first
      expect(config[:path]).to eq('users/show/:id')
      expect(config[:verbs].keys).to eq([:get])
    end

    it 'marks components without standalone as not standalone-routed' do
      comp_class = Class.new(Compony::Component) do
        setup do
          label(:all) { 'Nested' }
          content { div 'hi' }
        end
      end
      stub_const('Components::Tests::Nested', comp_class)
      expect(comp_class.new.standalone_configs.values.pluck(:path).compact).to be_empty
    end

    it 'records skip_authentication!' do
      config = Components::Statics::Home.new.standalone_configs.values.first
      expect(config[:skip_authentication]).to be(true)
    end
  end

  describe 'resourceful' do
    it 'marks resourceful components' do
      expect(Components::Users::Show.new.resourceful?).to be(true)
      expect(Components::Statics::Home.new.resourceful?).to be(false)
    end

    it 'infers the data class from the family name' do
      expect(Components::Users::Show.new.data_class).to eq(User)
    end
  end
end
