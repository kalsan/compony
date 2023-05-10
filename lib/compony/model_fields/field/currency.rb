module Compony
  module ModelFields
    class Field
      class Currency < Field
        def value_for(data, controller: nil, **_)
          return transform_and_join(data.send(@name), controller:) { |el| controller.helpers.number_to_currency(el) }
        end
      end
    end
  end
end
