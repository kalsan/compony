module Compony
  module ModelFields
    class Field
      class Float < Field
        protected

        def resolve_filter_keys!
          ["#{@name}-eq".to_sym, "#{@name}-lteq".to_sym, "#{@name}-gteq".to_sym]
        end
      end
    end
  end
end
