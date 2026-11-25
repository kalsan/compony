RSpec.describe Compony::ModelFields::Attachment do
  # The dummy app does not load Active Storage, so the attachment reflection and the attachments are stand-ins.
  let(:many_reflection_class) { Class.new }
  let(:model_class) do
    reflection = many_reflection_class.new
    Class.new { define_singleton_method(:reflect_on_attachment) { |_name| reflection } }
  end
  let(:attachments) do
    [
      double(id: 1, signed_id: 'signed-1', filename: 'one.pdf'),
      double(id: 2, signed_id: 'signed-2', filename: 'two.pdf')
    ]
  end
  let(:record) do
    double(new_record?: false, model_name: ActiveModel::Name.new(User), files: attachments)
  end
  let(:form) do
    double(object: record).tap do |form|
      helpers = ActionController::Base.helpers
      allow(form).to receive(:label) { |name| helpers.label_tag(name) }
      allow(form).to receive(:input) { |name, **| helpers.file_field_tag("user[#{name}][]") }
    end
  end

  before { stub_const('ActiveStorage::Reflection::HasManyAttachedReflection', many_reflection_class) }

  describe 'simpleform_input of an existing record with several attachments' do
    subject(:html) { described_class.new(:files, model_class).simpleform_input(form, nil) }

    it 'submits each present attachment through a checked checkbox, so unticking it removes the attachment' do
      expect(html).to include('<input type="checkbox" name="user[files][]" id="user_files_keep_1" value="signed-1"')
      expect(html).to include('<input type="checkbox" name="user[files][]" id="user_files_keep_2" value="signed-2"')
      expect(html.scan('checked="checked"').size).to eq(2)
      expect(html).to include('<label class="compony-attachments-filename" for="user_files_keep_1">one.pdf</label>')
    end

    it 'renders no inline JavaScript' do
      expect(html).not_to match(/javascript:|\bon[a-z]+=/)
    end
  end
end
