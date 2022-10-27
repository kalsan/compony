module Compony
  module Components
    # This component is used for the _form partial in the Rails paradigm.
    class Form < Component
      def check_config!
        super
        fail "#{inspect} requires config.form_fields do ..." if @form_fields.blank?
      end

      setup do
        before_render do
          # Must render the buttons now as the rendering within simple form breaks the form
          @submit_button = Compony.button(
            label: @submit_label || I18n.t('compony.components.form.submit'), icon: 'arrow-right', type: :submit
          ).render(controller)
          @submit_path = @comp_opts[:submit_path]
          @submit_path = @submit_path.call(controller) if @submit_path.respond_to?(:call)
        end

        content do
          form_html = simple_form_for(data, method: @comp_opts[:submit_verb], url: @submit_path) do |f|
            component.with_form_helper(Compony.form_helper_class.new(f, component)) do
              instance_exec &form_fields
              div @submit_button, class: 'compony-form-buttons'
            end
          end
          text_node form_html
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

      # DSL method, use to provide autocomplete for a TomSelect
      def autocomplete(field_name, data_class_name = nil, ransack:)
        last_path_segment = "autocomplete_#{field_name}" # This must match the custom simpleform input, if any.
        data_class_name ||= field_name.to_s.classify

        standalone last_path_segment.to_sym, path: "#{family_name}/#{comp_name}/#{last_path_segment}" do
          verb :get do
            respond do
              res = data_class_name.safe_constantize.accessible_by(current_ability).ransack(ransack => params[:q]).result
              controller.render(json: res.map do |u|
                                        {
                                          text:  u.label,
                                          value: u.id
                                        }
                                      end)
            end
          end
        end
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
          field_group = data.class.field_groups[field_group_key]
          return proc do
            field_group.fields.each do |_field_name, field|
              instance_exec(&field.schema_call)
            end
          end
        end
      end

      # This method is used by render to store the form helper inside the component such that we can delegate
      # the method `field` to the helper. This is a workaround required because the form does not exist when the
      # RequestContext is being built, and we want the method `field` to be available inside the `form_fields` block.
      def with_form_helper(form_helper, &block)
        @form_helper = form_helper
        yield
        @form_helper = nil
      end

      # Called inside the form_fields block. This makes the method `field` available in the block.
      # See also notes for `with_form_helper`.
      def field(...)
        fail("The `field` method may only be called inside `form_fields` for #{inspect}.") unless @form_helper
        return @form_helper.field(...)
      end

      # Called inside the form_fields block. This makes the method `f` available in the block.
      # See also notes for `with_form_helper`.
      def f(...)
        fail("The `f` method may only be called inside `form_fields` for #{inspect}.") unless @form_helper
        return @form_helper.form(...)
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
        @field_group_key || :default
      end
    end
  end
end
