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
          anchormodel_class = model_field.model_class.anchormodel_attributes[model_field.name].anchormodel_class
          opts = {
            collection:   collect(anchormodel_class.all),
            label_method: :first,
            value_method: :second,
            selected:     selected_cst&.key || anchormodel_class.all.first
          }.merge(kwargs)
          return @form.input name, **opts
        when :rich_text
          return @form.input name, **kwargs.merge(as: :rich_text_area)
        else
          return @form.input name, **kwargs
        end
      end

      # Takes an array of objects implementing the methods `label` and `key` and returns an array suitable for simple_form select fields.
      def collect(flat_array, label_method: :label, key_method: :key)
        return flat_array.map { |entry| [entry.send(label_method), entry.send(key_method)] }
      end
    end
  end
end
