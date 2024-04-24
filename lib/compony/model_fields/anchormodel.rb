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
