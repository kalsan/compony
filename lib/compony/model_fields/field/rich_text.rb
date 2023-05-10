module Compony
  module ModelFields
    class Field
      class RichText < Field
        def simpleform_input(form, _component, **input_opts)
          return form.input @name, **input_opts.merge(as: :rich_text_area)
        end

        protected

        def resolve_filter_keys!
          @filter_keys = ["#{@name}-cont".to_sym]
        end
      end
    end
  end
end
