module Compony
  module ModelFields
    class Anchormodel < Base
      # Takes an array of objects implementing the methods `label` and `key` and returns an array suitable for simple_form select fields.
      def self.collect(flat_array, label_method: :label, key_method: :key)
        return flat_array.map { |entry| [entry.send(label_method), entry.send(key_method)] }
      end

      def value_for(data, controller: nil, **_)
        return transform_and_join(data.send(@name), controller:) { |el| el&.label }
      end

      def simpleform_input(form, _component, name: nil, **input_opts)
        anchormodel_attribute = @model_class.anchormodel_attributes[@name]
        anchormodel_class = anchormodel_attribute.anchormodel_class
        input_opts[:input_html] ||= {}
        # Attempt to read selected key from html input options "value", as the caller might not know that this is a select.
        selected_key = input_opts[:input_html].delete(:value) # can also be both nil or blank
        if selected_key.blank? && form.object
          # No selected key override present and a model is present, use the model to find out what to select
          selected_cst = form.object.send(@name)
          selected_key = selected_cst&.key || anchormodel_class.all.first
        end
        opts = {
          collection:    self.class.collect(anchormodel_class.all),
          label_method:  :first,
          value_method:  :second,
          selected:      selected_key, # if used in select
          checked:      selected_key, # if used in radio buttons
          include_blank: anchormodel_attribute.optional
        }.merge(input_opts)
        return form.input name || @name, **opts
      end

      def simpleform_input_hidden(form, _component, name: nil, **input_opts)
        if form.object
          selected_cst = form.object.send(@name)
          input_opts[:input_html] ||= {}
          input_opts[:input_html][:value] = selected_cst.is_a?(::Anchormodel) ? selected_cst.key : selected_cst
        end
        return form.input name || @name, as: :hidden, **input_opts
      end
    end
  end
end
