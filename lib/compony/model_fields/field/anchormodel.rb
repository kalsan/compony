module Compony
  module ModelFields
    class Field
      class Anchormodel < Field
        # Takes an array of objects implementing the methods `label` and `key` and returns an array suitable for simple_form select fields.
        def self.collect(flat_array, label_method: :label, key_method: :key)
          return flat_array.map { |entry| [entry.send(label_method), entry.send(key_method)] }
        end

        def value_for(data, controller: nil, **_)
          return transform_and_join(data.send(@name), controller:, &:label)
        end

        def simpleform_input(form, _component, **input_opts)
          selected_cst = form.object.send(@name)
          anchormodel_attribute = @model_class.anchormodel_attributes[@name]
          anchormodel_class = anchormodel_attribute.anchormodel_class
          opts = {
            collection:    self.class.collect(anchormodel_class.all),
            label_method:  :first,
            value_method:  :second,
            selected:      selected_cst&.key || anchormodel_class.all.first,
            include_blank: anchormodel_attribute.optional
          }.merge(input_opts)
          return form.input @name, **opts
        end

        protected

        def resolve_filter_keys!
          @filter_keys = [] # filtering on these types requires specifying the order key manually
        end
      end
    end
  end
end
