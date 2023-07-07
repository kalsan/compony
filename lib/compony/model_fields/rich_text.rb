module Compony
  module ModelFields
    class RichText < Base
      def simpleform_input(form, _component, name: nil, **input_opts)
        return form.input name || @name, **input_opts.merge(as: :rich_text_area)
      end
    end
  end
end
