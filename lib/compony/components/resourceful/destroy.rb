module Compony
  module Components
    module Resourceful
      # @api description
      # This component is used for the Rails destroy paradigm. Asks for confirm when queried using GET.
      class Destroy < Compony::Component
        include Compony::ComponentMixins::Resourceful

        setup do
          standalone path: "#{family_name}/:id/destroy" do
            verb :get do
              load_data(&default_load_data_block)
              accessible { defined?(can?) ? can?(:destroy, @data) : true }
            end
            verb :delete do
              load_data(&default_load_data_block)
              accessible { defined?(can?) ? can?(:destroy, @data) : true }
              store_data do
                # Validate params against the form's schema
                schema = Schemacop::Schema3.new :hash, additional_properties: true do
                  int! :id, cast_str: true
                end
                schema.validate!(controller.request.params)

                # Perform destroy
                @data.destroy!
              end
              respond do
                evaluate_with_backfire(&@on_destroyed_block)
              end
            end
          end

          label(:long) { |data| I18n.t('compony.components.destroy.label.long', data_label: data.label) }
          label(:short) { |_| I18n.t('compony.components.destroy.label.short') }
          icon { :trash }
          color { :danger }

          content do
            div I18n.t('compony.components.destroy.confirm_question', data_label: @data.label)
            div do
              concat compony_button(comp_cst,
                                    @data,
                                    label:  I18n.t('compony.components.destroy.confirm_button'),
                                    method: :delete)
            end
          end

          on_destroyed do
            flash.notice = I18n.t('compony.components.destroy.data_was_destroyed', data_label: @data.label)
            redirect_to evaluate_with_backfire(&@on_destroyed_redirect_path_block), status: :see_other # 303: force GET
          end

          on_destroyed_redirect_path do
            Compony.path(:index, family_cst)
          end
        end

        def load_data(controller)
          @data = data_class.find(controller.params[:id])
        end

        # DSL method
        def on_destroyed(&block)
          @on_destroyed_block = block
        end

        # DSL method
        def on_destroyed_redirect_path(&block)
          @on_destroyed_redirect_path_block = block
        end
      end
    end
  end
end
