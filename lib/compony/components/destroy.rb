module Compony
  module Components
    # @api description
    # This component is used for the Rails destroy paradigm. Asks for confirm when queried using GET.
    class Destroy < Compony::Component
      include Compony::ComponentMixins::Resourceful

      setup do
        standalone path: "#{family_name}/:id/destroy" do
          verb :get do
            authorize { can?(:destroy, @data) }
          end

          verb :delete do
            authorize { can?(:destroy, @data) }
            store_data # This enables the global store_data block defined below for this path and verb.
            respond do
              evaluate_with_backfire(&@on_destroyed_block) if @on_destroyed_block
              evaluate_with_backfire(&@on_destroyed_respond_block)
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

        action :back_to_owner do
          next if data_class.owner_model_attr.blank?
          Compony.button(:show, @data.send(@data_class.owner_model_attr), icon: :xmark, color: :secondary, label: I18n.t('compony.cancel'))
        end

        store_data do
          # Validate params against the form's schema
          local_data = @data # Capture data for usage in the Schemacop call
          schema = Schemacop::Schema3.new :hash, additional_properties: true do
            if local_data.class.primary_key_type_key == :string
              str! :id
            else
              int! :id, cast_str: true
            end
          end
          schema.validate!(controller.request.params)

          # Perform destroy
          @data.destroy!
        end

        on_destroyed_respond do
          flash.notice = I18n.t('compony.components.destroy.data_was_destroyed', data_label: @data.label)
          redirect_to evaluate_with_backfire(&@on_destroyed_redirect_path_block), status: :see_other # 303: force GET
        end

        on_destroyed_redirect_path do
          if data_class.owner_model_attr.present?
            Compony.path(:show, @data.send(data_class.owner_model_attr))
          else
            Compony.path(:index, family_cst)
          end
        end
      end

      # DSL method
      # Sets a block that is evaluated with backfire in the successful case after storing, but before responding.
      def on_destroyed(&block)
        @on_destroyed_block = block
      end

      # DSL method
      def on_destroyed_respond(&block)
        @on_destroyed_respond_block = block
      end

      # DSL method
      def on_destroyed_redirect_path(&block)
        @on_destroyed_redirect_path_block = block
      end
    end
  end
end
