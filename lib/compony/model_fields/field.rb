module Compony
  module ModelFields
    class Field
      SUPPORTED_TYPES = %i[
        association
        anchormodel
        boolean
        currency
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
      attr_reader :order_key
      attr_reader :filter_key
      attr_reader :schema_key

      def multi?
        !!@multi
      end

      def association?
        !!@association
      end

      # @param order_key [Symbol] :auto = autocompute, nil = prohibit sorting
      # @param filter_key [Symbol] :auto = autocompute, nil = prohibit sorting
      def initialize(name, model_class, type:, order_key:, filter_key:)
        @type = type.to_sym
        @order_key = order_key&.to_sym
        @filter_key = filter_key
        fail("Unsupported field type #{@type.inspect}, supported are: #{SUPPORTED_TYPES.pretty_inspect}") unless SUPPORTED_TYPES.include?(type)
        @name = name.to_sym
        @model_class = model_class
        @schema_key = name
        resolve_association! if type == :association
        resolve_order_key! if order_key == :auto
        resolve_filter_key! if filter_key == :auto
      end

      # Use this to display the label for this field, e.g. for columns, forms etc.
      def label
        @model_class.human_attribute_name(@name)
      end

      # Use this to display the value for this field applied to data
      def value_for(data, link_to_component: nil, link_opts: {}, controller: nil)
        fail('If link_to_component is specified, must also pass controller') if link_to_component && controller.nil?
        if association?
          if link_to_component
            return transform_and_join(data.send(@name), controller:) do |el|
                     el.nil? ? nil : controller.helpers.compony_link(link_to_component, el, **link_opts)
                   end
          else
            return transform_and_join(data.send(@name), controller:) { |el| el&.label }
          end
        else
          case @type
          when :date, :datetime
            return transform_and_join(data.send(@name), controller:) { |el| el.nil? ? nil : I18n.l(el) }
          when :boolean
            return transform_and_join(data.send(@name), controller:) { |el| I18n.t("compony.boolean.#{el}") }
          when :anchormodel
            return data.send(@name)&.label
          when :currency
            return transform_and_join(data.send(@name), controller:) { |el| controller.helpers.number_to_currency(el) }
          else
            return transform_and_join(data.send(@name), controller:)
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
          return proc { obj? local_schema_key }
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

      # Provides a default for auto-dectection, but can be overridden by giving the value explicitely in the `field` call.
      # This is meant to work with ransack (extra functionality not built into Compony)
      def resolve_order_key!
        @order_key = case @type
                     when :association_single, :association_multi
                       nil # sorting on these types requires specifying the order key manually
                     else
                       @name
                     end
      end

      # Provides a default for auto-dectection, but can be overridden by giving the value explicitely in the `field` call.
      # This is meant to work with ransack (extra functionality not built into Compony)
      def resolve_filter_key!
        @filter_key = case @type
                      when :anchormodel, :association_single, :association_multi
                        nil # filtering on these types requires specifying the order key manually
                      when :rich_text, :string, :text
                        "#{@name}_cont".to_sym
                      else
                        "#{@name}_eq".to_sym
                      end
      end

      # If given a scalar, calls the block on the scalar. If given a list, calls the block on every member and joins the result with ",".
      def transform_and_join(data, controller:, &transform_block)
        if data.is_a?(Enumerable)
          data = data.compact.map(&transform_block) if block_given?
          return controller.helpers.safe_join(data.compact, ', ')
        else
          data = transform_block.call(data) if block_given?
          return data
        end
      end
    end
  end
end
