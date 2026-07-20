RSpec.describe 'Compony::ModelFields' do
  let(:user) do
    User.create!(name: 'Alice', age: 30, comment: 'Hi', email: 'alice@example.com', admin: true, born_on: Date.new(1990, 5, 6))
  end

  describe 'value_for' do
    it 'returns the raw value for string fields' do
      expect(User.fields[:name].value_for(user)).to eq('Alice')
    end

    it 'formats booleans via I18n' do
      value = User.fields[:admin].value_for(user)
      expect(value).to be_present
      expect(value).not_to eq(true) # must be a human-readable representation, not the raw boolean
    end

    it 'localizes dates' do
      expect(User.fields[:born_on].value_for(user)).to eq(I18n.l(Date.new(1990, 5, 6)))
    end

    it 'renders emails as mailto links when given a controller' do
      controller = ApplicationController.new
      controller.set_request!(ActionDispatch::Request.new({}))
      value = User.fields[:email].value_for(user, controller:)
      expect(value).to include('mailto:alice@example.com')
    end

    it 'fails for emails without controller' do
      expect { User.fields[:email].value_for(user) }.to raise_error(RuntimeError, /Must pass controller/)
    end

    it 'returns nil-safe values for blank fields' do
      empty = User.create!(name: 'Bob')
      expect(User.fields[:born_on].value_for(empty)).to be_blank
      expect(User.fields[:email].value_for(empty, controller: ApplicationController.new)).to be_blank
    end
  end

  describe 'label' do
    it 'uses human_attribute_name' do
      expect(User.fields[:name].label).to eq(User.human_attribute_name(:name))
    end
  end

  describe 'schema_line' do
    it 'returns a proc for schemacop integration' do
      expect(User.fields[:name].schema_line).to be_a(Proc)
    end
  end
end
