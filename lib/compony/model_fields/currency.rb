module Compony
  module ModelFields
    class Currency < Base
      def value_for(data, controller: nil, **_)
        return transform_and_join(data.send(@name), controller:) { |el| controller.helpers.number_to_currency(el) }
      end
    end
  end
end
