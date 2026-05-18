module Compony
  module Components
    # @api description
    # This component is used for the Rails new and create paradigm. Performs update when the form is submitted.
    class New < Compony::Components::WithForm
      include Compony::ComponentMixins::Resourceful

      setup do
        submit_verb :post
        load_data { @data = data_class.new }
        standalone path: "#{family_name}/new" do
          verb :get do
            authorize { can?(:new, data_class) }
            assign_attributes # This enables the global assign_attributes block defined below for this path and verb.
          end
          verb submit_verb do
            authorize { can?(:create, @data) }
            assign_attributes # This enables the global assign_attributes block defined below for this path and verb.
            store_data # This enables the global store_data block defined below for this path and verb.
            respond do
              if @create_succeeded
                evaluate_with_backfire(&@on_created_block) if @on_created_block
                evaluate_with_backfire(&@on_created_respond_block)
              else
                evaluate_with_backfire(&@on_create_failed_respond_block)
              end
            end
          end
        end

        label(:long) { I18n.t('compony.components.new.label.long', data_class: data_class.model_name.human) }
        label(:short) { I18n.t('compony.components.new.label.short') }

        form_cancancan_action :new

        content :label do
          h2 component.label
        end

        content do
          concat form_comp.render(controller, data: @data)
        end

        assign_attributes do
          local_form_comp = form_comp # Capture form_comp for usage in the Schemacop call
          local_data = @data # Capture data for usage in the Schemacop call
          local_controller = controller # Capture controller for usage in the Schemacop call
          schema = Schemacop::Schema3.new :hash, additional_properties: true do
            hsh? local_form_comp.schema_wrapper_key_for(local_data), &local_form_comp.schema_block_for(local_data, local_controller)
          end
          validated_params = schema.validate!(controller.request.params)
          attrs_to_assign = validated_params[form_comp.schema_wrapper_key_for(@data)]
          @data.assign_attributes(attrs_to_assign) if attrs_to_assign
        end

        store_data do
          @create_succeeded = @data.save
        end

        on_created_respond do
          flash.notice = I18n.t('compony.components.new.data_was_created', data_label: data.label)
          redirect_to evaluate_with_backfire(&@on_created_redirect_path_block)
        end

        on_created_redirect_path do
          if Compony.comp_class_for(:show, @data)
            Compony.path(:show, @data)
          elsif data_class.owner_model_attr.present?
            Compony.path(:show, @data.send(data_class.owner_model_attr))
          else
            Compony.path(:index, family_name)
          end
        end

        on_create_failed_respond do
          Rails.logger.warn(@data&.errors&.full_messages)
          render_standalone(controller, status: :unprocessable_content)
        end
      end

      # @!group DSL

      # DSL method
      # Sets an optional hook evaluated (with backfire) after a successful create but before responding.
      # Suitable for post-create side effects (like an `after_create` that only fires when this component created the record).
      # Do not redirect or render here - use {#on_created_respond} / {#on_created_redirect_path} for that.
      # @yield Runs in the component's request context after `@data` was saved successfully.
      # @return [void]
      # @api public
      def on_created(&block)
        @on_created_block = block
      end

      # DSL method
      # Overrides the response issued after a successful create. The default shows a flash and redirects to
      # {#on_created_redirect_path}. If you override this, {#on_created_redirect_path} is no longer called.
      # @yield Runs in the component's request context; expected to render or redirect.
      # @return [void]
      # @api public
      def on_created_respond(&block)
        @on_created_respond_block = block
      end

      # DSL method
      # Overrides the redirect target used by the default {#on_created_respond} (keeping the default flash).
      # Defaults to the data's Show, the owner's Show, or the data's Index.
      # @yield Runs in the component's request context; expected to return a Rails path (e.g. via `Compony.path`).
      # @return [void]
      # @api public
      def on_created_redirect_path(&block)
        @on_created_redirect_path_block = block
      end

      # DSL method
      # Overrides the response issued when the create failed (`@create_succeeded` is not true).
      # The default logs the errors with level `warn` and re-renders the component with HTTP 422 so the form shows errors.
      # @yield Runs in the component's request context; expected to render or redirect.
      # @return [void]
      # @api public
      def on_create_failed_respond(&block)
        @on_create_failed_respond_block = block
      end

      # @!endgroup
    end
  end
end
