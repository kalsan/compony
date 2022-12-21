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

      def field(name, **kwargs)
        hidden = kwargs.delete(:hidden)
        model_field = @form.object.fields[name.to_sym]
        fail("Field #{name.to_sym.inspect} is not defined on #{@form.object.inspect}") unless model_field

        if hidden
          return @form.input model_field.schema_key, as: :hidden, **kwargs
        end

        case model_field.type
        when :association
          return @form.association name, **kwargs
        when :anchormodel
          selected_cst = @form.object.send(name)
          anchor_class = model_field.model_class.anchormodel_attributes[model_field.name].anchor_class
          opts = {
            collection:   anchor_class.all.map { |anchor| [anchor.label, anchor.key] },
            label_method: :first,
            value_method: :second,
            selected:     selected_cst&.key || anchor_class.all.first
          }.merge(kwargs)
          return @form.input name, **opts
        else
          return @form.input name, **kwargs
        end
      end
    end
  end
end
