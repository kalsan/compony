module Compony
  module Components
    module Resourceful
      # This component is used for the Rails new and create paradigm. Performs update when the form is submitted.
      class New < Compony::Components::WithForm
        include Compony::ComponentMixins::Resourceful

        setup do
          submit_verb :post
          standalone path: "#{family_name}/new" do
            verb :get do
              load_data { @data = data_class.new }
              accessible { defined?(can?) ? can?(:create, data_class) : true }
            end
            verb submit_verb do
              load_data { @data = data_class.new }
              accessible { defined?(can?) ? can?(:create, data_class) : true }
              store_data do
                # Validate params against the form's schema
                local_form_comp = form_comp # Capture form_comp for usage in the Schemacop call
                local_data = @data # Capture data for usage in the Schemacop call
                schema = Schemacop::Schema3.new :hash, additional_properties: true do
                  hsh! local_form_comp.schema_wrapper_key_for(local_data), &local_form_comp.schema_block_for(local_data)
                end
                schema.validate!(controller.request.params)

                # Perform save
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

            on_created do
              flash.notice = compony_t('%{data} was created.') % { data: @data.label }
              redirect_to compony_path(:show, family_cst, id: @data.id)
            end
            on_create_failed do
              render_standalone(controller, status: :unprocessable_entity)
            end
          end

          label(:long) { compony_t('New %{data_class}') % { data_class: compony_t(data_class.to_s) } }
          label(:short) { compony_t('New') }
          icon { :plus }

          content <<~HAML
            = form_comp.render(controller, data: @data)
          HAML

          action :back do
            Compony.button_comp(:index, family_cst, icon: :'chevron-left', color: :secondary)
          end
        end

        # DSL method
        def on_created(&block)
          @on_created_block = block
        end

        # DSL method
        def on_create_failed(&block)
          @on_create_failed_block = block
        end
      end
    end
  end
end
