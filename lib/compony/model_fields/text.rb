module Compony
  module ModelFields
    class Text < Base
      protected

      def resolve_filter_keys!
        @filter_keys = ["#{@name}-cont".to_sym]
      end
    end
  end
end
