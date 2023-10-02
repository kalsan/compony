module Compony
  module ModelFields
    class Color < Base
      def value_for(data, controller: nil, **_)
        return transform_and_join(data.send(@name), controller:) do |el|
          next nil unless el
          next controller.helpers.raw "#{el}&nbsp;<span style=\"background-color: #{el}\">&nbsp;&nbsp;&nbsp;&nbsp;</span>"
        end
      end

      def simpleform_input(form, _component, name: nil, **input_opts)
        return form.input name || @name, as: :color, **input_opts
      end
    end
  end
end
