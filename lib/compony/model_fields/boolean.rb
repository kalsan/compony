module Compony
  module ModelFields
    class Boolean < Base
      def value_for(data, controller: nil, **_)
        return transform_and_join(data.send(@name), controller:) { |el| I18n.t("compony.boolean.#{el}") }
      end

      protected

      def resolve_filter_keys!
        ["#{@name}-true".to_sym, "#{@name}-false".to_sym]
      end
    end
  end
end
