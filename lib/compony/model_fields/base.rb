module Compony
  module ModelFields
    class Base
      attr_reader :name
      attr_reader :model_class
      attr_reader :schema_key
      attr_reader :extra_attrs

      def multi?
        !!@multi
      end

      def association?
        !!@association
      end

      def initialize(name, model_class, **extra_attrs)
        @name = name.to_sym
        @model_class = model_class
        @schema_key = name
        @extra_attrs = extra_attrs
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
      def simpleform_input(form, _component, name: nil, **input_opts)
        return form.input name || @name, **input_opts
      end

      # Used in form helper
      # Given a simpleform instance, returns a suitable hidden input for thetype
      def simpleform_input_hidden(form, _component, name: nil, **input_opts)
        return form.input name || @name, as: :hidden, **input_opts
      end

      protected

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
