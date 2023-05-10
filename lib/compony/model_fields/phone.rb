module Compony
  module ModelFields
    # Requires 'phonelib' gem
    class Phone < Base
      def initialize(...)
        fail('Please include gem "phonelib" to use the :phone field type.') unless defined?(Phonelib)
        super
      end

      def value_for(data, controller: nil, **_)
        return transform_and_join(data.send(@name), controller:) { |el| Phonelib.parse(el).international }
      end
    end
  end
end
