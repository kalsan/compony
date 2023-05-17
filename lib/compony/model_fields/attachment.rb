module Compony
  module ModelFields
    # @api description
    # Model field type representing an ActiveStorage attachment.
    class Attachment < Base
      def value_for(data, controller: nil, **_)
        return transform_and_join(data.send(@name), controller:) do |el|
          fail('Must pass controller to generate the link to the attachment.') unless controller
          return nil unless el.attached?
          return controller.helpers.link_to(I18n.t('compony.model_fields.attachment.download'), controller.helpers.rails_blob_path(el))
        end
      end

      def simpleform_input(form, _component, accept: nil, **input_opts)
        input_opts.merge!(input_html: { accept: }) if accept
        return form.input(:proof_photo, **input_opts)
      end
    end
  end
end
