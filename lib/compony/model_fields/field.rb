module Compony
  module ModelFields
    class Field
      SUPPORTED_TYPES = %i[
        association
        anchormodel
        boolean
        date
        datetime
        decimal
        float
        integer
        rich_text
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
      def value_for(data, link_to_component: nil, link_opts: {}, controller: nil)
        fail('If link_to_component is specified, must also pass controller') if link_to_component && controller.nil?
        if association?
          if multi?
            if link_to_component
              return data.send(@name).map do |item|
                controller.helpers.compony_link(link_to_component, item)
              end.join(', ')
            else
              return data.send(@name).map(&:label).join(', ')
            end
          elsif link_to_component
            return controller.helpers.compony_link(link_to_component, data.send(@name), **link_opts)
          else
            return data.send(@name)&.label
          end
        else
          case @type
          when :date, :datetime
            val = data.send(@name)
            return val.nil? ? nil : I18n.l(val)
          when :boolean
            return I18n.t("compony.boolean.#{data.send(@name)}")
          when :anchormodel
            return data.send(@name)&.label
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
        association_info = @model_class.reflect_on_association(@name) || fail("Association #{@name.inspect} does not exist for #{@model_class.inspect}.")
        @multi = association_info.macro == :has_many
        @type = @multi ? :association_multi : :association_single
        foreign_key = association_info.foreign_key
        @schema_key = @multi ? foreign_key.pluralize.to_sym : foreign_key.to_sym
      rescue ActiveRecord::NoDatabaseError
        Rails.logger.warn('Warning: Compony could not auto-detect fields due to missing database. This is ok when running db:create.')
      end
    end
  end
end
