module Compony
  module ModelFields
    class Base
      attr_reader :name
      attr_reader :model_class
      attr_reader :order_key
      attr_reader :filter_keys
      attr_reader :schema_key

      def multi?
        !!@multi
      end

      def association?
        !!@association
      end

      # @param order_key [Symbol] omitted, nil = prohibit sorting
      # @param filter_keys [Array] omitted, [] = prohibit filtering
      def initialize(name, model_class, order_key:, auto_order_key:, filter_keys:, auto_filter_keys:)
        @order_key = order_key&.to_sym
        @filter_keys = filter_keys
        @name = name.to_sym
        @model_class = model_class
        @schema_key = name

        resolve_order_key! if auto_order_key
        resolve_filter_keys! if auto_filter_keys
      end

      # Use this to display the label for this field, e.g. for columns, forms etc.
      def label
        @model_class.human_attribute_name(@name)
      end

      # Use this to display the value for this field applied to data
      def value_for(data, controller: nil, **_)
        # Default behavior
        return transform_and_join(data.send(@name), controller:)
      end

      # Used for auto-providing Schemacop schemas.
      # Returns a proc that is meant for instance_exec within a Schemacop3 hash block
      def schema_line
        # Default behavior
        local_schema_key = @schema_key # Capture schema_key as it will not be available within the lambda
        return proc { obj? local_schema_key }
      end

      # Used in form helper.
      # Given a simpleform instance, returns the corresponding input to be supplied to the view.
      def simpleform_input(form, _component, **input_opts)
        return form.input @name, **input_opts
      end

      protected

      # Provides a default for auto-dectection, but can be overridden by giving the value explicitely in the `field` call.
      # This is meant to work with ransack (extra functionality not built into Compony)
      def resolve_order_key!
        # Default behavior
        @order_key = @name
      end

      # Provides a default for auto-dectection, but can be overridden by giving the value explicitely in the `field` call.
      # This is meant to work with ransack (extra functionality not built into Compony)
      def resolve_filter_keys!
        # Default behavior
        @filter_keys = ["#{@name}-eq".to_sym]
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
