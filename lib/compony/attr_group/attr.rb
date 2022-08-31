module Compony
  class AttrGroup
    # This class provides utility functions for attributes in an attr_group,
    # most of them involving the data from the model the attr_group was meant for.
    # To make use of this feature, use AttrGroup's attrs_for method.
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
        @data.class.human_attribute_name(@attr_key)
      end

      # Retrieves and presents the actual value of the attribute of the model, e.g. "John" for :first_name and an instance of User
      # Secrets are hidden, collections are presented using commata.
      def value
        case @mode
        when :attribute
          return @data.send(@attr_key)
        when :password
          return I18n.t('compony.filtered')
        when :association
          res = @data.send(@attr_key)
          if res.is_a?(Enumerable)
            return res.map(&:label).join(', ')
          else
            return res.label
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
          # Find the kind of key we are looking for (e.g. shelf.book_ids or bookmark.book_id)
          multi = @data.class.reflect_on_association(attr_key).macro == :has_many
          foreign_key = @data.class.reflect_on_association(attr_key).foreign_key
          id_key = multi ? foreign_key.pluralize : foreign_key
          if multi
            return proc do
              ary? id_key.pluralize.to_sym do
                list :integer, cast_str: true
              end
            end
          else
            return proc do
              int? id_key.to_sym, cast_str: true
            end
          end
        else
          return proc { str? local_attr_key }
        end
      end
    end
  end
end
