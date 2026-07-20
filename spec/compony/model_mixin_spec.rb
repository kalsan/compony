RSpec.describe Compony::ModelMixin do
  describe '.field' do
    it 'registers fields with the correct types' do
      expect(User.fields[:name]).to be_a(Compony::ModelFields::String)
      expect(User.fields[:age]).to be_a(Compony::ModelFields::Integer)
      expect(User.fields[:comment]).to be_a(Compony::ModelFields::Text)
      expect(User.fields[:email]).to be_a(Compony::ModelFields::Email)
      expect(User.fields[:admin]).to be_a(Compony::ModelFields::Boolean)
      expect(User.fields[:born_on]).to be_a(Compony::ModelFields::Date)
      expect(User.fields[:created_at]).to be_a(Compony::ModelFields::Datetime)
    end

    it 'keeps the field name and model class' do
      field = User.fields[:name]
      expect(field.name).to eq(:name)
      expect(field.model_class).to eq(User)
    end

    it 'rebinds fields to the subclass on inheritance' do
      subclass = Class.new(User)
      expect(subclass.fields[:name].model_class).to eq(subclass)
      expect(User.fields[:name].model_class).to eq(User) # parent untouched
    end

    it 'does not leak fields defined on a subclass into the parent' do
      subclass = Class.new(User) do
        def self.name = 'SpecialUser'
        field :extra, :string
      end
      expect(subclass.fields).to have_key(:extra)
      expect(User.fields).not_to have_key(:extra)
    end
  end

  describe 'feasibility' do
    it 'is feasible when no prevention triggers' do
      user = User.create!(name: 'Alice', admin: false)
      expect(user.feasible?(:destroy)).to be(true)
      expect(user.feasibility_messages(:destroy)).to eq([])
      expect(user.full_feasibility_messages(:destroy)).to eq('')
    end

    it 'is infeasible when a prevention triggers' do
      admin = User.create!(name: 'Root', admin: true)
      expect(admin.feasible?(:destroy)).to be(false)
      expect(admin.feasibility_messages(:destroy)).to eq(['Cannot destroy admins'])
      expect(admin.full_feasibility_messages(:destroy)).to eq('Cannot destroy admins.')
    end

    it 'caches the result until recompute is requested' do
      user = User.create!(name: 'Alice', admin: false)
      expect(user.feasible?(:destroy)).to be(true)
      user.admin = true
      expect(user.feasible?(:destroy)).to be(true) # cached
      expect(user.feasible?(:destroy, recompute: true)).to be(false)
    end

    it 'returns true for unknown actions' do
      user = User.create!(name: 'Alice')
      expect(user.feasible?(:frobnicate)).to be(true)
    end
  end

  describe '.owned_by' do
    it 'stores the owner attribute' do
      klass = Class.new(User) do
        def self.name = 'OwnedUser'
        owned_by :parent
      end
      expect(klass.owner_model_attr).to eq(:parent)
      expect(User.owner_model_attr).to be_nil
    end
  end

  describe '#field' do
    it 'returns the formatted value for a field' do
      user = User.create!(name: 'Alice', age: 30)
      expect(user.field(:name, nil)).to eq('Alice')
    end
  end
end
