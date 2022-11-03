module Compony
  module ModelFields
    class Field
      SUPPORTED_TYPES = %i[
        association
        boolean
        date
        datetime
        decimal
        float
        integer
        string
        text
        time
      ].freeze

      attr_reader :name
      attr_reader :model_class
      attr_reader :type
      attr_reader :schema_key

      def multi?
        !!@multi
      end

      def association?
        !!@association
      end

      # If `type` is passed explicitely, resolve! is skipped.
      def initialize(name, model_class, type:)
        @type = type.to_sym
        fail("Unsupported field type #{@type.inspect}, supported are: #{SUPPORTED_TYPES.pretty_inspect}") unless SUPPORTED_TYPES.include?(type)
        @name = name.to_sym
        @model_class = model_class
        @schema_key = name
        resolve_association! if type == :association
      end

      # Use this to display the label for this field, e.g. for columns, forms etc.
      def label
        @model_class.human_attribute_name(@name)
      end

      # Use this to display the value for this field applied to data
      def value_for(data)
        if association?
          if multi?
            return data.send(@name).map(&:label).join(', ')
          else
            return data.send(@name)&.label
          end
        else
          case @type
          when :date, :datetime
            val = data.send(@name)
            return val.nil? ? nil : I18n.l(val)
          when :boolean
            val = I18n.t("compony.boolean.#{data.send(@name)}")
          else
            return data.send(@name)
          end
        end
      end

      # Used for auto-providing Schemacop schemas.
      # Returns a proc that is meant for instance_exec within a Schemacop3 hash block
      def schema_call
        local_schema_key = @schema_key # Capture schema_key as it will not be available within the lambda
        if association?
          if multi?
            return proc do
              ary? local_schema_key do
                list :integer, cast_str: true
              end
            end
          else
            return proc do
              int? local_schema_key, cast_str: true
            end
          end
        else
          return proc { str? local_schema_key }
        end
      end

      protected

      # Uses Rails methods to figure out the arity, schema key etc. and store them.
      # This can be auto-inferred without accessing the database.
      def resolve_association!
        fail("Attempted to resolve association for non-association type #{@type} on #{inspect}") unless @type == :association
        @association = true
        @multi = @model_class.reflect_on_association(@name).macro == :has_many
        @type = @multi ? :association_multi : :association_single
        foreign_key = @model_class.reflect_on_association(@name).foreign_key
        @schema_key = @multi ? foreign_key.pluralize.to_sym : foreign_key.to_sym
      rescue ActiveRecord::NoDatabaseError
        Rails.logger.warn('Warning: Compony could not auto-detect fields due to missing database. This is ok when running db:create.')
      end
    end
  end
end
