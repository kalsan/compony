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
          # Fake submit button rendered by a button component and submitting the form via JS:
          concat render_intent(name: :submit, label: @submit_label || I18n.t('compony.components.form.submit'), button: {
                                 onclick: "this.closest('form').requestSubmit(); return false;"
                               })
          # Real (but hidden) submit button to allow Return to submit:
          button type: :submit, hidden: true
        end

        # Override this to provide additional submit buttons.
        content :buttons, hidden: true do
          content(:submit_button)
        end

        content do
          form_params = { method: @comp_opts[:submit_verb], url: @submit_path }.merge(@form_params || {})
          form_html = simple_form_for(data, **form_params) do |f|
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

      # @!group DSL

      # DSL method, use to set the form content (mandatory).
      # The block holds the form inputs and is instance-exec'd in the form's request context where `field`, `pw_field` and `f` are available.
      # @yield Builds the form body using Dyny + the form field helpers.
      # @return [Proc,nil] When called without a block, returns the stored block.
      # @api public
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

      # DSL method (inside `form_fields`). Renders a simple_form input inferred from the model field `name`.
      # Respects per-field CanCanCan authorization; skipped fields render nothing.
      # @param name [Symbol,String] The model field (use the association name, not the `_id`, for associations).
      # @param multilang [Boolean] If true, generates one suffixed input per available locale and returns the array (useful with the "mobility" gem).
      # @param input_opts [Hash] Passed to simple_form. Notable keys: `as:` (input type), `hidden: true`, `autofocus:`.
      # @return [String,Array<String>] The input HTML (array when `multilang`).
      # @api public
      def field(name, multilang: false, **input_opts)
        fail("The `field` method may only be called inside `form_fields` for #{inspect}.") unless @simpleform

        if multilang
          I18n.available_locales.map { |locale| field("#{name}_#{locale}", **input_opts) }
        else
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
      end

      # DSL method (inside `form_fields`). Renders a password input; should be used for `:password` and `:password_confirmation`.
      # Checks the `:set_password` CanCanCan ability; `:hidden` is intentionally unsupported here.
      # @param name [Symbol,String] The password field name.
      # @param input_opts [Hash] Passed to simple_form.
      # @return [String,nil] The input HTML, or nil if not permitted.
      # @api public
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

      # DSL method (inside `form_fields`). Returns the underlying simple_form builder, e.g. for `f.rich_text_area`
      # or `f.simple_fields_for` (nested attributes).
      # @return [SimpleForm::FormBuilder] The simple_form builder for the current form.
      # @api public
      def f
        fail("The `f` method may only be called inside `form_fields` for #{inspect}.") unless @simpleform
        return @simpleform
      end

      # Quick access for wrapping collections in Rails compatible format
      def collect(...)
        Compony::ModelFields::Anchormodel.collect(...)
      end

      # DSL method, disables all inputs.
      # @return [void]
      # @api public
      def disable!
        @form_disabled = true
      end

      # DSL method, customizes the parameters given to `simple_form_for`.
      # @param new_form_params [Hash] Extra kwargs forwarded to `simple_form_for`.
      # @return [void]
      # @api public
      def form_params(**new_form_params)
        @form_params = new_form_params
      end

      # @!endgroup

      protected

      # @!group DSL

      # DSL method, adds a Schemacop3 line whitelisting param(s) inside the schema's wrapper.
      # @yield Runs in a Schemacop3 context, e.g. `str? :foo`.
      # @return [void]
      # @api public
      def schema_line(&block)
        @schema_lines_for_data << proc { |_data, _controller| block }
      end

      # DSL method, whitelists a single field of `data_class` in the param schema, auto-generating the correct schema line.
      # Respects per-field CanCanCan authorization.
      # @param field_name [Symbol,String] The model field (association name, not `_id`, for associations).
      # @param multilang [Boolean] If true, whitelists one suffixed field per available locale (useful with the "mobility" gem).
      # @return [void]
      # @api public
      def schema_field(field_name, multilang: false)
        if multilang
          I18n.available_locales.each { |locale| schema_field("#{field_name}_#{locale}") }
        else
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
      end

      # DSL method, whitelists a password param in the schema (checks the `:set_password` permission).
      # @param field_name [Symbol,String] The password field name.
      # @return [void]
      # @api public
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

      # DSL method, whitelists several fields at once (see {#schema_field}).
      # @param field_names [Array<Symbol,String>] The model fields to whitelist.
      # @return [void]
      # @api public
      def schema_fields(*field_names)
        field_names.each { |field_name| schema_field(field_name) }
      end

      # DSL method, replaces the form's schema and wrapper key with a completely manual Schemacop3 schema.
      # @param wrapper_key [Symbol,String] The top-level params wrapper key (e.g. the model's singular name).
      # @yield Runs in a Schemacop3 context defining the wrapped params.
      # @return [void]
      # @api public
      def schema(wrapper_key, &block)
        if block_given?
          @schema_wrapper_key = wrapper_key
          @schema_block = block
        else
          fail 'schema requires a block to be given'
        end
      end

      # DSL method, skips adding autofocus to the first field.
      # @return [void]
      # @api public
      def skip_autofocus
        @skip_autofocus = true
      end

      # @!endgroup
    end
  end
end
