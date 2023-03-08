module Compony
  module Components
    module Resourceful
      # @api description
      # This component is used for the Rails new and create paradigm. Performs update when the form is submitted.
      class New < Compony::Components::WithForm
        include Compony::ComponentMixins::Resourceful

        setup do
          submit_verb :post
          standalone path: "#{family_name}/new" do
            verb :get do
              authorize { can?(:create, data_class) }
              load_data do
                # Allowing GET params to pre-set values (new only).
                @data = data_class.new
                instance_exec(&schema_validator)
                attrs_to_assign = controller.request.params[form_comp.schema_wrapper_key_for(@data)]
                @data.assign_attributes(attrs_to_assign) if attrs_to_assign
              end
            end
            verb submit_verb do
              authorize { can?(:create, data_class) }
              load_data { @data = data_class.new }
              store_data do
                instance_exec(&schema_validator)
                @data = data_class.new(controller.request.params[form_comp.schema_wrapper_key_for(@data)])
                @create_succeeded = @data.save
              end
              respond do
                if @create_succeeded
                  evaluate_with_backfire(&@on_created_block)
                else
                  evaluate_with_backfire(&@on_create_failed_block)
                end
              end
            end
          end

          label(:long) { I18n.t('compony.components.new.label.long', data_class: data_class.model_name.human) }
          label(:short) { I18n.t('compony.components.new.label.short') }
          icon { :plus }

          content do
            concat form_comp.render(controller, data: @data)
          end

          on_created do
            flash.notice = I18n.t('compony.components.new.data_was_created', data_label: data.label)
            redirect_to evaluate_with_backfire(&@on_created_redirect_path_block)
          end

          on_created_redirect_path do
            if Compony.comp_class_for(:show, @data)
              Compony.path(:show, @data)
            else
              Compony.path(:index, @data)
            end
          end

          on_create_failed do
            Rails.logger.warn(@data&.errors&.full_messages)
            render_standalone(controller, status: :unprocessable_entity)
          end
        end

        def schema_validator
          return proc do
            local_form_comp = form_comp # Capture form_comp for usage in the Schemacop call
            local_data = @data # Capture data for usage in the Schemacop call
            schema = Schemacop::Schema3.new :hash, additional_properties: true do
              hsh? local_form_comp.schema_wrapper_key_for(local_data), &local_form_comp.schema_block_for(local_data)
            end
            schema.validate!(controller.request.params)
          end
        end

        # DSL method
        def on_created(&block)
          @on_created_block = block
        end

        # DSL method
        def on_created_redirect_path(&block)
          @on_created_redirect_path_block = block
        end

        # DSL method
        def on_create_failed(&block)
          @on_create_failed_block = block
        end
      end
    end
  end
end
