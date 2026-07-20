RSpec.describe Compony do
  describe '.family_name_for' do
    it 'underscores strings and symbols' do
      expect(described_class.family_name_for('Users')).to eq('users')
      expect(described_class.family_name_for(:Users)).to eq('users')
      expect(described_class.family_name_for(:users)).to eq('users')
    end

    it 'derives the family from a model instance' do
      expect(described_class.family_name_for(User.new)).to eq('users')
    end

    it 'derives the family from a model class' do
      expect(described_class.family_name_for(User)).to eq('users')
    end
  end

  describe '.comp_class_for' do
    it 'resolves a component from comp and family symbols' do
      expect(described_class.comp_class_for(:show, :users)).to eq(Components::Users::Show)
    end

    it 'resolves a component from a model instance' do
      expect(described_class.comp_class_for(:show, User.new)).to eq(Components::Users::Show)
    end

    it 'returns nil for a missing component' do
      expect(described_class.comp_class_for(:missing, :users)).to be_nil
    end
  end

  describe '.comp_class_for!' do
    it 'fails for a missing component' do
      expect { described_class.comp_class_for!(:missing, :users) }.to raise_error(RuntimeError, /No component found/)
    end

    it 'resolves an existing component' do
      expect(described_class.comp_class_for!(:edit, :users)).to eq(Components::Users::Edit)
    end
  end

  describe '.intent' do
    it 'builds an intent' do
      intent = described_class.intent(:show, :users)
      expect(intent).to be_a(Compony::Intent)
      expect(intent.comp_class).to eq(Components::Users::Show)
    end

    it 'passes through an existing intent' do
      intent = described_class.intent(:show, :users)
      expect(described_class.intent(intent)).to be(intent)
    end
  end

  describe '.path' do
    it 'generates the path for a component with a model' do
      user = User.create!(name: 'Alice')
      expect(described_class.path(:show, user)).to eq("/users/show/#{user.id}")
    end

    it 'generates the path for a component without model' do
      expect(described_class.path(:index, :users)).to eq('/users')
    end
  end

  describe '.button_component_class' do
    it 'returns the default css button class' do
      expect(described_class.button_component_class).to eq(Compony::Components::Buttons::CssButton)
    end

    it 'returns the link class for :link' do
      expect(described_class.button_component_class(:link)).to eq(Compony::Components::Buttons::Link)
    end

    it 'fails for an unknown style' do
      expect { described_class.button_component_class(:nope) }.to raise_error(RuntimeError, /Unknown button style/)
    end
  end

  describe '.default_button_style' do
    it 'defaults to :css_button' do
      expect(described_class.default_button_style).to eq(:css_button)
    end
  end

  describe '.model_field_class_for' do
    it 'resolves built-in field classes' do
      expect(described_class.model_field_class_for('String')).to eq(Compony::ModelFields::String)
      expect(described_class.model_field_class_for('Date')).to eq(Compony::ModelFields::Date)
    end

    it 'fails for unknown field types' do
      expect { described_class.model_field_class_for('Nope') }.to raise_error(RuntimeError, /No `model_field_namespace`/)
    end
  end

  describe '.model_field_namespaces' do
    it 'defaults to the built-in namespace' do
      expect(described_class.model_field_namespaces).to eq(['Compony::ModelFields'])
    end
  end
end
