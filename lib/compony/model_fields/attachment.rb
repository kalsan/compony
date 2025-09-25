module Compony
  module ModelFields
    # @api description
    # Model field type representing an ActiveStorage attachment.
    class Attachment < Base
      def initialize(...)
        super
        resolve_attachment!
      end

      def value_for(data, controller: nil, **_)
        return transform_and_join(data.send(@name), controller:) do |el|
          fail('Must pass controller to generate the link to the attachment.') unless controller
          if @multi
            return nil if el.none?
            return controller.helpers.safe_join(el.map { |item| controller.helpers.link_to(item.filename, controller.helpers.rails_blob_path(item)) }, ', ')
          else
            return nil unless el.attached?
            return controller.helpers.link_to(el.filename, controller.helpers.rails_blob_path(el))
          end
        end
      end

      def simpleform_input(form, _component, name: nil, accept: nil, **input_opts)
        name ||= @name
        input_opts.deep_merge!(input_html: { accept: }) if accept
        if @multi
          if form.object.new_record?
            # signed id is only calculated when the attachment is actually attached, cannot provide buttons for new records
            return form.input(name, **input_opts.deep_merge(input_html: { multiple: :multiple }))
          else
            helpers = ActionController::Base.helpers
            return helpers.capture do
              helpers.concat form.label(name)
              # List currently present attachments along with a remove button (done in JS)
              helpers.div class: 'compony-attachments-item-wrapper' do
                form.object.send(name).each do |attachment|
                  helpers.div class: 'compony-attachments-item' do
                    helpers.concat helpers.hidden_field_tag("#{form.object.model_name.singular}[#{name}][]", attachment.signed_id)
                    helpers.span attachment.filename, class: 'compony-attachments-filename'
                    helpers.span ' ', class: 'compony-attachments-spacer'
                    helpers.concat helpers.link_to(I18n.t('compony.model_fields.attachment.remove'), '#',
                                                   onclick: "event.preventDefault(); this.closest('div').remove();")
                  end
                end
              end
              helpers.concat form.input(name, **input_opts.deep_merge(input_html: { multiple: :multiple }, label: false, class: 'compony-attachments-input'))
            end
          end
        end
        return form.input(name, **input_opts)
      end

      protected

      # Uses Rails method to figure out arity and store it.
      # This can be auto-inferred without accessing the database.
      def resolve_attachment!
        attachment_info = model_class.reflect_on_attachment(name)
        @multi = attachment_info.is_a?(ActiveStorage::Reflection::HasManyAttachedReflection)
      end
    end
  end
end
