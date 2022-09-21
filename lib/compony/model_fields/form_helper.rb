module Compony
  module ModelFields
    # This is injected into the context of a form's call to form_fields.
    # It connects forms to ModelFields.
    class FormHelper
      attr_reader :form
      attr_reader :comp

      def initialize(form, comp)
        @form = form
        @comp = comp
      end

      def field(name, **kwargs)
        model_field = @form.object.fields[name.to_sym]
        fail("Field #{name.to_sym.inspect} is not defined on #{@form.object.inspect}") unless model_field
        if model_field.association?
          return @form.association name, **kwargs
        else
          return @form.input name, **kwargs
        end
      end
    end
  end
end
