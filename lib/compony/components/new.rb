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
            authorize { can?(:create, data_class) }
            assign_attributes # This enables the global assign_attributes block defined below for this path and verb.
          end
          verb submit_verb do
            authorize { can?(:create, data_class) }
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
        icon { :plus }

        add_content do
          h2 component.label
        end
        add_content do
          concat form_comp.render(controller, data: @data)
        end

        assign_attributes do
          local_form_comp = form_comp # Capture form_comp for usage in the Schemacop call
          local_data = @data # Capture data for usage in the Schemacop call
          schema = Schemacop::Schema3.new :hash, additional_properties: true do
            hsh? local_form_comp.schema_wrapper_key_for(local_data), &local_form_comp.schema_block_for(local_data)
          end
          schema.validate!(controller.request.params)

          # TODO: Why are we not saving the validated params?
          attrs_to_assign = controller.request.params[form_comp.schema_wrapper_key_for(@data)]
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
          elsif data_class.containing_model_attr.present?
            Compony.path(:show, @data.send(data_class.containing_model_attr))
          else
            Compony.path(:index, @data)
          end
        end

        on_create_failed_respond do
          Rails.logger.warn(@data&.errors&.full_messages)
          render_standalone(controller, status: :unprocessable_entity)
        end
      end

      # DSL method
      # Sets a block that is evaluated with backfire in the successful case after storing, but before responding.
      def on_created(&block)
        @on_created_block = block
      end

      # DSL method
      def on_created_respond(&block)
        @on_created_respond_block = block
      end

      # DSL method
      def on_created_redirect_path(&block)
        @on_created_redirect_path_block = block
      end

      # DSL method
      def on_create_failed_respond(&block)
        @on_create_failed_respond_block = block
      end
    end
  end
end
