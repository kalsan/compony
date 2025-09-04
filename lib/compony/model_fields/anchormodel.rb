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
          am_attr = form.object.class.anchormodel_attributes[@name]
          am_serializer = (am_attr.multiple? ? ::Anchormodel::ActiveModelTypeValueMulti : ::Anchormodel::ActiveModelTypeValueSingle).new(am_attr)
          input_opts[:input_html] ||= {}
          input_opts[:input_html][:value] = am_serializer.serialize(selected_cst)
        end
        return form.input name || @name, as: :hidden, **input_opts
      end

      def ransack_filter_name
        :"#{@name}_eq"
      end

      def ransack_filter_input(form, **input_opts)
        form.select(
          ransack_filter_name,
          self.class.collect(@model_class.anchormodel_attributes[@name].anchormodel_class.all),
          { include_blank: true },
          { class: input_opts[:filter_select_class] }
        )
      end
    end
  end
end
