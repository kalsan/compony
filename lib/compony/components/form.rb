module Compony
  module Components
    # @api description
    # This component is used for the _form partial in the Rails paradigm.
    class Form < Component
      def initialize(...)
        @schema_lines_for_data = [] # Array of procs taking data returning a Schemacop proc
        super
      end

      def check_config!
        super
        fail "#{inspect} requires config.form_fields do ..." if @form_fields.blank?
      end

      setup do
        before_render do
          # Must render the buttons now as the rendering within simple form breaks the form
          @submit_button = Compony.button_component_class.new(
            label: @submit_label || I18n.t('compony.components.form.submit'), icon: 'arrow-right', type: :submit
          ).render(controller)
          @submit_path = @comp_opts[:submit_path]
          @submit_path = @submit_path.call(controller) if @submit_path.respond_to?(:call)
        end

        content do
          form_html = simple_form_for(data, method: @comp_opts[:submit_verb], url: @submit_path) do |f|
            component.with_simpleform(f) do
              instance_exec(&form_fields)
              div @submit_button, class: 'compony-form-buttons'
            end
          end
          concat form_html
        end
      end

      # DSL method, use to set the form content
      def form_fields(&block)
        return @form_fields unless block_given?
        @form_fields = block
      end

      # Attr reader for @schema_wrapper_key with auto-calculated default
      def schema_wrapper_key_for(data)
        if @schema_wrapper_key.present?
          return @schema_wrapper_key
        else
          # If schema was not called, auto-infer a default
          data.model_name.singular
        end
      end

      # Attr reader for @schema_block with auto-calculated default
      def schema_block_for(data)
        if @schema_block
          return @schema_block
        else
          # If schema was not called, auto-infer a default
          local_schema_lines_for_data = @schema_lines_for_data
          return proc do
            local_schema_lines_for_data.each do |schema_line|
              instance_exec(&schema_line.call(data))
            end
          end
        end
      end

      # This method is used by render to store the simpleform instance inside the component such that we can call
      # methods from inside `form_fields`. This is a workaround required because the form does not exist when the
      # RequestContext is being built, and we want the method `field` to be available inside the `form_fields` block.
      # @todo Refactor? Could this be greatly simplified by having `form_field to |f|` ?
      def with_simpleform(simpleform)
        @simpleform = simpleform
        yield
        @simpleform = nil
      end

      # Called inside the form_fields block. This makes the method `field` available in the block.
      # See also notes for `with_simpleform`.
      def field(name, **input_opts)
        fail("The `field` method may only be called inside `form_fields` for #{inspect}.") unless @simpleform

        hidden = input_opts.delete(:hidden)
        model_field = @simpleform.object.fields[name.to_sym]
        fail("Field #{name.to_sym.inspect} is not defined on #{@simpleform.object.inspect} but was requested in #{inspect}.") unless model_field

        if hidden
          return @simpleform.input model_field.schema_key, as: :hidden, **input_opts
        else
          return model_field.simpleform_input(@simpleform, self, **input_opts)
        end
      end

      # Called inside the form_fields block. This makes the method `f` available in the block.
      # See also notes for `with_simpleform`.
      def f
        fail("The `f` method may only be called inside `form_fields` for #{inspect}.") unless @simpleform
        return @simpleform
      end

      # Quick access for wrapping collections in Rails compatible format
      def collect(...)
        Compony::ModelFields::Anchormodel.collect(...)
      end

      protected

      # DSL method, adds a new line to the schema whitelisting a single param inside the schema's wrapper
      def schema_line(&block)
        @schema_lines_for_data << proc { block }
      end

      # DSL method, adds a new field to the schema whitelisting a single field of data_class
      # This auto-generates the correct schema line for the field.
      def schema_field(field_name)
        @schema_lines_for_data << proc do |data|
          field = data.class.fields[field_name.to_sym] || fail("No field #{field_name.to_sym.inspect} found for #{data.inspect} in #{inspect}.")
          next field.schema_line
        end
      end

      # DSL method, mass-assigns schema fields
      def schema_fields(*field_names)
        field_names.each { |field_name| schema_field(field_name) }
      end

      # DSL method, use to replace the form's schema and wrapper key for a completely manual schema
      def schema(wrapper_key, &block)
        if block_given?
          @schema_wrapper_key = wrapper_key
          @schema_block = block
        else
          fail 'schema requires a block to be given'
        end
      end
    end
  end
end
