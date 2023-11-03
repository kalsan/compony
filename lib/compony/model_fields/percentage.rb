module Compony
  module ModelFields
    class Percentage < Base
      def value_for(data, controller: nil, **_)
        return transform_and_join(data.send(@name), controller:) { |el| controller.helpers.sanitize "#{(el * 100.0).round(2)}%" }
      end
    end
  end
end
