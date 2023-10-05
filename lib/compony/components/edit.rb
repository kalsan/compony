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

        content do
          concat form_comp.render(controller, data: @data)
        end

        assign_attributes do
          # Validate params against the form's schema
          local_form_comp = form_comp # Capture form_comp for usage in the Schemacop call
          local_data = @data # Capture data for usage in the Schemacop call
          schema = Schemacop::Schema3.new :hash, additional_properties: true do
            if local_data.class.primary_key_type_key == :string
              str! :id
            else
              int! :id, cast_str: true
            end
            hsh? local_form_comp.schema_wrapper_key_for(local_data), &local_form_comp.schema_block_for(local_data)
          end
          schema.validate!(controller.request.params)

          # TODO: Why are we not saving the validated params?
          attrs_to_assign = controller.request.params[form_comp.schema_wrapper_key_for(@data)]
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
          elsif data_class.containing_model_attr.present?
            Compony.path(:show, @data.send(data_class.containing_model_attr))
          else
            Compony.path(:index, @data)
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
