RSpec.describe Compony::Components::Form do
  describe 'multilang' do
    around do |example|
      original_available_locales = I18n.available_locales
      I18n.available_locales = %i[en de de-CH fr es]
      Compony.content_locales = %i[de en fr es]
      example.run
    ensure
      I18n.available_locales = original_available_locales
      Compony.content_locales = nil
    end

    let(:form) { described_class.new }

    it 'renders one field per content locale' do
      form.instance_variable_set(:@simpleform, Object.new) # `field` refuses to run outside `form_fields`
      allow(form).to receive(:field).and_call_original
      allow(form).to receive(:field).with(a_string_starting_with('label_')) { |name| name }
      expect(form.field(:label, multilang: true)).to eq(%w[label_de label_en label_fr label_es])
    end

    it 'whitelists one schema field per content locale' do
      allow(form).to receive(:schema_field).and_call_original
      form.send(:schema_field, :label, multilang: true) # DSL method, protected
      %w[label_de label_en label_fr label_es].each do |name|
        expect(form).to have_received(:schema_field).with(name)
      end
      expect(form).not_to have_received(:schema_field).with('label_de-CH')
    end
  end
end
