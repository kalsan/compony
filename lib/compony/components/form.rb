module Compony
  module Components
    # @api description
    # This component is used for the _form partial in the Rails paradigm.
    class Form < Component
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
            component.with_form_helper(Compony.form_helper_class.new(f, component)) do
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

      # DSL method, if given, allows to use "field" instead of "f.input" inside `form_fields`
      def field_group(field_group_key)
        @field_group_key = field_group_key.to_sym
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
          current_field_group = data.class.field_groups[field_group_key] || fail("Missing field group #{field_group_key.inspect} for #{data.class}")
          return proc do
            current_field_group.fields.each do |_field_name, field|
              instance_exec(&field.schema_call)
            end
          end
        end
      end

      # This method is used by render to store the form helper inside the component such that we can delegate
      # the method `field` to the helper. This is a workaround required because the form does not exist when the
      # RequestContext is being built, and we want the method `field` to be available inside the `form_fields` block.
      # @todo Refactor? Could this be greatly simplified by having `form_field to |f|` ?
      def with_form_helper(form_helper)
        @form_helper = form_helper
        yield
        @form_helper = nil
      end

      # Called inside the form_fields block. This makes the method `field` available in the block.
      # See also notes for `with_form_helper`.
      def field(name, **kwargs)
        fail("The `field` method may only be called inside `form_fields` for #{inspect}.") unless @form_helper
        unless @form_helper.form.object.field_groups[field_group_key]
          fail("No field group #{field_group_key.inspect} found for #{@form_helper.form.object.class}")
        end
        unless @form_helper.form.object.field_groups[field_group_key].fields.include?(name.to_sym)
          fail("Component #{self} is operating on field group #{field_group_key} which does not include requested field #{name.to_sym.inspect}.")
        end
        return @form_helper.field(name, **kwargs)
      end

      # Called inside the form_fields block. This makes the method `f` available in the block.
      # See also notes for `with_form_helper`.
      def f(...)
        fail("The `f` method may only be called inside `form_fields` for #{inspect}.") unless @form_helper
        return @form_helper.form(...)
      end

      # Called inside the form_fields block. This makes the method `f` available in the block.
      # See also notes for `with_form_helper`.
      def collect(...)
        fail("The `collect` method may only be called inside `form_fields` for #{inspect}.") unless @form_helper
        return @form_helper.collect(...)
      end

      protected

      # DSL method, use to set the form's schema and wrapper key
      def schema(wrapper_key, &block)
        if block_given?
          @schema_wrapper_key = wrapper_key
          @schema_block = block
        else
          fail 'schema requires a block to be given'
        end
      end

      # Protected attr reader with a default
      def field_group_key
        @field_group_key || :form
      end
    end
  end
end
