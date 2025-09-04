module Compony
  module ModelFields
    class Integer < Base
      def ransack_filter_name
        :"#{@name}_eq"
      end
    end
  end
end
