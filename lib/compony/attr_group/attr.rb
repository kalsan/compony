module Compony
  class AttrGroup
    # This class provides utility functions for attributes in an attr_group,
    # most of them involving the data from the model the attr_group was meant for.
    # To make use of this feature, use AttrGroup's each_attr_for method.
    class Attr
      ACCEPTED_MODES = %i[attribute password association].freeze

      attr_reader :attr_group
      attr_reader :attr_key
      attr_reader :mode
      attr_reader :data

      def initialize(attr_group, attr_key, mode, data)
        @attr_group = attr_group
        @attr_key = attr_key
        @mode = mode
        @data = data
      end

      def label
        compony_t(@attr_group.translation_key_for(@data, @attr_key))
      end

      # Retrieves and presents the actual value of the attribute of the model, e.g. "John" for :first_name and an instance of User
      # Secrets are hidden, collections are presented using commata.
      def value
        case @mode
        when :attribute
          return @data.send(@attr_key)
        when :password
          return compony_t('[filtered]')
        when :association
          res = @data.send(@attr_key).map(&:label)
          if res.is_a?(Enumerable)
            return res.join(', ')
          else
            return res
          end
        else
          fail "Unknown attr mode #{@mode}, AttrGroup should have prevented this."
        end
      end

      # Used for auto-providing Schemacop schemas.
      # Returns a proc that is meant for instance_exec within a Schemacop3 hash block
      def schema_call
        local_attr_key = @attr_key # Capture attr_key for usage in the lambda
        case @mode
        when :association
          return proc do
            ary? "#{local_attr_key.to_s.singularize}_ids".to_sym do
              list :integer, cast_str: true
            end
          end
        else
          return proc { str? local_attr_key }
        end
      end
    end
  end
end
