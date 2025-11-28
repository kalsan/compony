module Compony
  module Components
    # @api description
    # This component is used for the Rails edit and update paradigm. Performs update when the form is submitted.
    class Edit < Compony::Components::WithForm
      include Compony::ComponentMixins::Resourceful

      setup do
        submit_verb :patch
        standalone path: "#{family_name}/:id/edit" do
          verb :get do
            authorize { can?(:edit, @data) }
            assign_attributes # This enables the global assign_attributes block defined below for this path and verb.
          end
          verb submit_verb do
            authorize { can?(:update, @data) }
            assign_attributes # This enables the global assign_attributes block defined below for this path and verb.
            store_data # This enables the global store_data block defined below for this path and verb.
            respond do
              if @update_succeeded
                evaluate_with_backfire(&@on_updated_block) if @on_updated_block
                evaluate_with_backfire(&@on_updated_respond_block)
              else
                evaluate_with_backfire(&@on_update_failed_block)
              end
            end
          end
        end

        label(:long) { |data| I18n.t('compony.components.edit.label.long', data_label: data.label) }
        label(:short) { |_| I18n.t('compony.components.edit.label.short') }
        icon { :pencil }

        form_cancancan_action :edit

        exposed_intents do
          if data_class.owner_model_attr
            add :show, @data.send(data_class.owner_model_attr),
                button: { icon: :xmark, color: :secondary },
                label:  I18n.t('compony.cancel'),
                name:   :back_to_owner
          end
        end

        content :label do
          h2 component.label
        end

        content do
          concat form_comp.render(controller, data: @data)
        end

        assign_attributes do
          # Validate params against the form's schema
          local_form_comp = form_comp # Capture form_comp for usage in the Schemacop call
          local_data = @data # Capture data for usage in the Schemacop call
          local_controller = controller # Capture controller for usage in the Schemacop call
          schema = Schemacop::Schema3.new :hash, additional_properties: true do
            any_of! :id do
              str
              int cast_str: true
            end
            hsh? local_form_comp.schema_wrapper_key_for(local_data), &local_form_comp.schema_block_for(local_data, local_controller)
          end
          validated_params = schema.validate!(controller.request.params)
          attrs_to_assign = validated_params[form_comp.schema_wrapper_key_for(@data)]
          @data.assign_attributes(attrs_to_assign) if attrs_to_assign
        end

        store_data do
          @update_succeeded = @data.save
        end

        on_updated_respond do
          flash.notice = I18n.t('compony.components.edit.data_was_updated', data_label: data.label)
          redirect_to evaluate_with_backfire(&@on_updated_redirect_path_block)
        end

        on_updated_redirect_path do
          if Compony.comp_class_for(:show, @data)
            Compony.path(:show, @data)
          elsif data_class.owner_model_attr.present?
            Compony.path(:show, @data.send(data_class.owner_model_attr))
          else
            Compony.path(:index, family_name)
          end
        end

        on_update_failed do
          Rails.logger.warn(@data&.errors&.full_messages)
          render_standalone(controller, status: :unprocessable_entity)
        end
      end

      # DSL method
      # Sets a block that is evaluated with backfire in the successful case after storing, but before responding.
      def on_updated(&block)
        @on_updated_block = block
      end

      # DSL method
      def on_updated_respond(&block)
        @on_updated_respond_block = block
      end

      # DSL method
      def on_updated_redirect_path(&block)
        @on_updated_redirect_path_block = block
      end

      # DSL method
      def on_update_failed(&block)
        @on_update_failed_block = block
      end
    end
  end
end
