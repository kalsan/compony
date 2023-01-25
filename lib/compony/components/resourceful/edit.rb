module Compony
  module Components
    module Resourceful
      # @api description
      # This component is used for the Rails edit and update paradigm. Performs update when the form is submitted.
      class Edit < Compony::Components::WithForm
        include Compony::ComponentMixins::Resourceful
        setup do
          submit_verb :patch
          standalone path: "#{family_name}/:id/edit" do
            verb :get do
              load_data(&default_load_data_block)
              accessible { defined?(can?) ? can?(:edit, @data) : true }
            end
            verb submit_verb do
              load_data(&default_load_data_block)
              accessible { defined?(can?) ? can?(:update, @data) : true }
              store_data do
                # Validate params against the form's schema
                local_form_comp = form_comp # Capture form_comp for usage in the Schemacop call
                local_data = @data # Capture data for usage in the Schemacop call
                schema = Schemacop::Schema3.new :hash, additional_properties: true do
                  if local_data.class.primary_key_type_key == :string
                    str! :id
                  else
                    int! :id, cast_str: true
                  end
                  hsh! local_form_comp.schema_wrapper_key_for(local_data), &local_form_comp.schema_block_for(local_data)
                end
                schema.validate!(controller.request.params)

                # Perform save
                @data.assign_attributes(controller.request.params[form_comp.schema_wrapper_key_for(@data)])
                @update_succeeded = @data.save
              end
              respond do
                if @update_succeeded
                  evaluate_with_backfire(&@on_updated_block)
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

          on_updated do
            flash.notice = I18n.t('compony.components.edit.data_was_updated', data_label: data.label)
            redirect_to evaluate_with_backfire(&@on_updated_redirect_path_block)
          end

          on_updated_redirect_path do
            if Compony.comp_class_for(:show, @data)
              Compony.path(:show, @data)
            else
              Compony.path(:index, @data)
            end
          end

          on_update_failed do
            render_standalone(controller, status: :unprocessable_entity)
          end
        end

        # DSL method
        def on_updated(&block)
          @on_updated_block = block
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
end
