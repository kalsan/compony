module Compony
  module Components
    # This component is used for the _form partial in the Rails paradigm.
    class Form < Component
      def check_config!
        super
        fail "#{inspect} requires config.form_fields = <<~HAML..." if @form_fields.blank?
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

        content <<~HAML
          = simple_form_for(data, method: @comp_opts[:submit_verb], url: @submit_path) do |f|
            - form_request_context = Compony::RequestContext.new(component, controller, Compony.form_helper_class.new(f, component))
            - form_request_context._dslblend_transfer_inst_vars_from_main_provider
            = Haml::Engine.new(form_fields.strip_heredoc, format: :html5).render(form_request_context, { f: f })
            .compony-form-buttons
              = @submit_button
        HAML
      end

      # DSL method, use to set the form content
      def form_fields(form_fields = nil)
        return @form_fields unless form_fields
        @form_fields = form_fields
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
          current_field_group = data.class.field_groups[field_group_key]
          return proc do
            current_field_group.fields.each do |_field_name, field|
              instance_exec(&field.schema_call)
            end
          end
        end
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
