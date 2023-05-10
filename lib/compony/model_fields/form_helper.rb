module Compony
  module ModelFields
    # @api description
    # This is injected into the context of a form's call to form_fields.
    # It connects forms to ModelFields.
    class FormHelper
      attr_reader :form
      attr_reader :comp

      def initialize(form, comp)
        @form = form
        @comp = comp
      end

      def field(name, **input_opts)
        hidden = input_opts.delete(:hidden)
        model_field = @form.object.fields[name.to_sym]
        fail("Field #{name.to_sym.inspect} is not defined on #{@form.object.inspect}") unless model_field

        if hidden
          return @form.input model_field.schema_key, as: :hidden, **input_opts
        else
          return model_field.simpleform_input(@form, @comp, **input_opts)
        end
      end
    end
  end
end
