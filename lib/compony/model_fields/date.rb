module Compony
  module ModelFields
    class Date < Base
      def value_for(data, controller: nil, **_)
        return transform_and_join(data.send(@name), controller:) { |el| el.nil? ? nil : I18n.l(el) }
      end
    end
  end
end
