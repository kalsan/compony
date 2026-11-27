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

    context 'with multilang: true' do
      around do |example|
        original_available_locales = I18n.available_locales
        I18n.available_locales = %i[en de de-CH fr es]
        example.run
      ensure
        I18n.available_locales = original_available_locales
        Compony.content_locales = nil
      end

      def multilang_model
        Class.new(User) do
          def self.name = 'MultilangUser'
          field :label, :string, multilang: true
        end
      end

      it 'generates a virtual field plus one suffixed field per available locale by default' do
        expect(multilang_model.fields.keys - User.fields.keys).to eq(%i[label label_en label_de label_de-CH label_fr label_es])
        expect(multilang_model.fields[:label].extra_attrs).to eq(virtual: true)
      end

      it 'generates one suffixed field per content locale when configured' do
        Compony.content_locales = %i[de en fr es]
        expect(multilang_model.fields.keys - User.fields.keys).to eq(%i[label label_de label_en label_fr label_es])
      end
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

  describe 'dependent record detection' do
    let(:message) { I18n.t('compony.feasibility.has_dependent_models', dependent_class: FeasibilityItem.model_name.human(count: 2)) }

    before do
      stub_const('FeasibilityItem', Class.new(ApplicationRecord) { self.table_name = 'feasibility_items' })
      stub_const('FeasibilityOwner', Class.new(ApplicationRecord) do
        self.table_name = 'feasibility_owners'
        has_many :items, class_name: 'FeasibilityItem', foreign_key: :owner_id, dependent: :restrict_with_error
      end)
      stub_const('SpecialFeasibilityOwner', Class.new(FeasibilityOwner) do
        has_many :held_items, class_name: 'FeasibilityItem', as: :holder, dependent: :restrict_with_error
      end)
      stub_const('CustomFeasibilityOwner', Class.new(FeasibilityOwner) do
        prevent(:destroy, 'Custom prevention') { false }
      end)
      stub_const('CodedFeasibilityOwner', Class.new(ApplicationRecord) do
        self.table_name = 'feasibility_owners'
        self.inheritance_column = :_type_disabled
        has_many :coded_items, class_name: 'FeasibilityItem', primary_key: :code, foreign_key: :owner_code, dependent: :restrict_with_error
      end)
    end

    def count_queries(&)
      count = 0
      callback = ->(*, payload) { count += 1 unless payload[:name] == 'SCHEMA' }
      ActiveSupport::Notifications.subscribed(callback, 'sql.active_record', &)
      count
    end

    it 'prevents destroying a record with dependents' do
      owner = FeasibilityOwner.create!
      expect(owner.feasible?(:destroy)).to be(true)
      owner.items.create!
      expect(owner.feasible?(:destroy, recompute: true)).to be(false)
      expect(owner.feasibility_messages(:destroy)).to eq([message])
    end

    it 'detects the associations of an STI subclass after its parent was checked' do
      FeasibilityOwner.create!.feasible?(:destroy)
      special = SpecialFeasibilityOwner.create!
      special.held_items.create!
      expect(special.feasibility_messages(:destroy)).to eq([message])
    end

    it 'keeps the inherited associations in an STI subclass that defines its own preventions' do
      FeasibilityOwner.create!.feasible?(:destroy)
      custom = CustomFeasibilityOwner.create!
      custom.items.create!
      expect(custom.feasibility_messages(:destroy)).to eq([message])
    end

    it 'adds no prevention twice when parent and subclass were both checked' do
      FeasibilityOwner.create!.feasible?(:destroy)
      special = SpecialFeasibilityOwner.create!
      special.items.create!
      expect(special.feasibility_messages(:destroy)).to eq([message])
    end

    describe '.precompute_feasibility' do
      it 'matches dependents through the primary_key of the association' do
        owner = CodedFeasibilityOwner.create!(code: 'A')
        other = CodedFeasibilityOwner.create!(code: 'B')
        FeasibilityItem.create!(owner_code: 'A')
        FeasibilityItem.create!(owner_code: other.id.to_s) # matches the id of `other`, but not its code
        CodedFeasibilityOwner.precompute_feasibility([owner, other], :destroy)
        expect(owner.feasibility_messages(:destroy)).to eq([message])
        expect(other.feasibility_messages(:destroy)).to eq([])
      end

      it 'applies the preventions of STI subclasses to their records' do
        parent = FeasibilityOwner.create!
        special = SpecialFeasibilityOwner.create!
        special.held_items.create!
        FeasibilityOwner.precompute_feasibility([parent, special], :destroy)
        expect(parent.feasibility_messages(:destroy)).to eq([])
        expect(special.feasibility_messages(:destroy)).to eq([message])
      end

      it 'checks polymorphic associations in one query, matching the owner type' do
        owners = Array.new(3) { SpecialFeasibilityOwner.create! }
        owners.first.held_items.create!
        FeasibilityItem.create!(holder_id: owners.second.id, holder_type: 'User') # same id, other type
        queries = count_queries { SpecialFeasibilityOwner.precompute_feasibility(owners, :destroy) }
        expect(owners.map { |owner| owner.feasible?(:destroy) }).to eq([false, true, true])
        expect(queries).to eq(2) # one per association (items, held_items), independent of the number of records
      end

      it 'gives the same result as the per-record check' do
        owners = Array.new(3) { FeasibilityOwner.create! }
        owners.second.items.create!
        FeasibilityOwner.precompute_feasibility(owners, :destroy)
        batched = owners.map { |owner| owner.feasible?(:destroy) }
        expect(owners.map { |owner| owner.feasible?(:destroy, recompute: true) }).to eq(batched)
        expect(batched).to eq([true, false, true])
      end
    end
  end

  describe '.ransackable_associations' do
    it 'allows no association by default, with or without auth object' do
      expect(User.ransackable_associations).to eq([])
      expect(User.ransackable_associations(Ability.new(nil))).to eq([])
    end

    it 'can be overridden by a model' do
      klass = Class.new(User) do
        def self.name = 'SearchableUser'
        def self.ransackable_associations(_auth_object = nil) = %w[posts]
      end
      expect(klass.ransackable_associations).to eq(%w[posts])
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
