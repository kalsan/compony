module Compony
  module Components
    # @api description
    # This component is used for the _form partial in the Rails paradigm.
    class Form < Component
      def initialize(*args, cancancan_action: :missing, disabled: false, **kwargs)
        @schema_lines_for_data = [] # Array of procs taking data returning a Schemacop proc
        @cancancan_action = cancancan_action
        @form_disabled = disabled
        super
      end

      setup do
        before_render do
          # Make sure the error message is going to be nice if form_fields were not implemented
          fail "#{component.inspect} requires config.form_fields do ..." if @form_fields.nil?
          if @cancancan_action == :missing
            fail("Missing cancancan_action for #{component.inspect}, you must provide one (e.g. :edit) or pass nil explicitely.")
          end

          # Calculate paths
          @submit_path = @comp_opts[:submit_path]
          @submit_path = @submit_path.call(controller) if @submit_path.respond_to?(:call)
        end

        # Override this to provide a custom submit button
        content :submit_button, hidden: true do
          concat Compony.button_component_class.new(
            label: @submit_label || I18n.t('compony.components.form.submit'), icon: 'arrow-right', type: :submit
          ).render(controller)
        end

        # Override this to provide additional submit buttons.
        content :buttons, hidden: true do
          content(:submit_button)
        end

        content do
          form_html = simple_form_for(data, method: @comp_opts[:submit_verb], url: @submit_path) do |f|
            component.with_simpleform(f, controller) do
              instance_exec(&form_fields)
              div class: 'compony-form-buttons' do
                content(:buttons)
              end
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
      def schema_block_for(data, controller)
        if @schema_block
          return @schema_block
        else
          # If schema was not called, auto-infer a default
          local_schema_lines_for_data = @schema_lines_for_data
          return proc do
            local_schema_lines_for_data.each do |schema_line|
              schema_line_proc = schema_line.call(data, controller) # This may return nil, e.g. is the user is not authorized to set a field
              instance_exec(&schema_line_proc) unless schema_line_proc.nil?
            end
          end
        end
      end

      # This method is used by render to store the simpleform instance inside the component such that we can call
      # methods from inside `form_fields`. This is a workaround required because the form does not exist when the
      # RequestContext is being built, and we want the method `field` to be available inside the `form_fields` block.
      # @todo Refactor? Could this be greatly simplified by having `form_field to |f|` ?
      def with_simpleform(simpleform, controller)
        @simpleform = simpleform
        @controller = controller
        @focus_given = false
        yield
        @simpleform = nil
        @controller = nil
      end

      # Called inside the form_fields block. This makes the method `field` available in the block.
      # See also notes for `with_simpleform`.
      def field(name, **input_opts)
        fail("The `field` method may only be called inside `form_fields` for #{inspect}.") unless @simpleform
        name = name.to_sym

        input_opts.merge!(disabled: true) if @form_disabled

        # Check per-field authorization
        if @cancancan_action.present? && @controller.current_ability.permitted_attributes(@cancancan_action, @simpleform.object).exclude?(name)
          Rails.logger.debug do
            "Skipping form field #{name.inspect} because the current user is not allowed to perform #{@cancancan_action.inspect} on #{@simpleform.object}."
          end
          return
        end

        hidden = input_opts.delete(:hidden)
        model_field = @simpleform.object.fields[name]
        fail("Field #{name.inspect} is not defined on #{@simpleform.object.inspect} but was requested in #{inspect}.") unless model_field

        if hidden
          return model_field.simpleform_input_hidden(@simpleform, self, **input_opts)
        else
          unless @focus_given || @skip_autofocus
            input_opts[:autofocus] = true unless input_opts.key? :autofocus
            @focus_given = true
          end
          return model_field.simpleform_input(@simpleform, self, **input_opts)
        end
      end

      # Called inside the form_fields block. This makes the method pw_field available in the block.
      # This method should be called for the fields :password and :password_confirmation
      # Note that :hidden is not supported here, as this would make no sense in conjunction with :password or :password_confirmation.
      def pw_field(name, **input_opts)
        fail("The `pw_field` method may only be called inside `form_fields` for #{inspect}.") unless @simpleform
        name = name.to_sym

        # Check for authorization
        unless @cancancan_action.nil? || @controller.current_ability.can?(:set_password, @simpleform.object)
          Rails.logger.debug do
            "Skipping form pw_field #{name.inspect} because the current user is not allowed to perform :set_password on #{@simpleform.object}."
          end
          return
        end

        unless @focus_given || @skip_autofocus
          input_opts[:autofocus] = true unless input_opts.key? :autofocus
          @focus_given = true
        end
        return @simpleform.input name, **input_opts
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

      # DSL method, disables all inputs
      def disable!
        @form_disabled = true
      end

      protected

      # DSL method, adds a new line to the schema whitelisting a single param inside the schema's wrapper
      # The block should be something like `str? :foo` and will run in a Schemacop3 context.
      def schema_line(&block)
        @schema_lines_for_data << proc { |_data, _controller| block }
      end

      # DSL method, adds a new field to the schema whitelisting a single field of data_class
      # This auto-generates the correct schema line for the field.
      def schema_field(field_name)
        # This runs upon component setup.
        @schema_lines_for_data << proc do |data, controller|
          # This runs within a request context.
          field = data.class.fields[field_name.to_sym] || fail("No field #{field_name.to_sym.inspect} found for #{data.inspect} in #{inspect}.")
          # Check per-field authorization
          if @cancancan_action.present? && controller.current_ability.permitted_attributes(@cancancan_action.to_sym, data).exclude?(field.name.to_sym)
            Rails.logger.debug do
              "Skipping form schema_field #{field_name.inspect} because the current user is not allowed to perform #{@cancancan_action.inspect} on #{data}."
            end
            next nil
          end
          next field.schema_line
        end
      end

      # DSL method, adds a new password field to the schema whitelisting
      # This checks for the permission :set_password and auto-generates the correct schema line for the field.
      def schema_pw_field(field_name)
        # This runs upon component setup.
        @schema_lines_for_data << proc do |data, controller|
          # This runs within a request context.
          # Check per-field authorization
          unless @cancancan_action.nil? || controller.current_ability.can?(:set_password, data)
            Rails.logger.debug do
              "Skipping form schema_pw_field #{field_name.inspect} because the current user is not allowed to perform :set_password on #{data}."
            end
            next nil
          end
          next proc { obj? field_name.to_sym }
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

      # DSL method, skips adding autofocus to the first field
      def skip_autofocus
        @skip_autofocus = true
      end
    end
  end
end
