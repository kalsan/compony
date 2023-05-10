module Compony
  module ModelFields
    class Datetime < Base
      def value_for(data, controller: nil, **_)
        return transform_and_join(data.send(@name), controller:) { |el| el.nil? ? nil : I18n.l(el) }
      end

      protected

      def resolve_filter_keys!
        ["#{@name}-eq".to_sym, "#{@name}-lteq".to_sym, "#{@name}-gteq".to_sym]
      end
    end
  end
end
