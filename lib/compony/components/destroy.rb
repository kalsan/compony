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

        content :confirm_question, hidden: true do
          div I18n.t('compony.components.destroy.confirm_question', data_label: @data.label)
        end

        content :confirm_button, hidden: true do
          div do
            concat render_intent(comp_name,
                                 @data,
                                 label:  I18n.t('compony.components.destroy.confirm_button'),
                                 method: :delete)
          end
        end

        content do
          content :confirm_question
          content :confirm_button
        end

        exposed_intents do
          if data_class.owner_model_attr
            add :show, @data.send(data_class.owner_model_attr),
                label: I18n.t('compony.cancel'),
                name:  :back_to_owner
          end
        end

        store_data do
          # Validate params against the form's schema
          schema = Schemacop::Schema3.new :hash, additional_properties: true do
            any_of! :id do
              str
              int cast_str: true
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
            Compony.path(:index, family_name)
          end
        end
      end

      # @!group DSL

      # DSL method
      # Sets an optional hook evaluated (with backfire) after a successful destroy but before responding.
      # Suitable for post-destroy side effects (like an `after_destroy` that only fires when this component destroyed the record).
      # Do not redirect or render here - use {#on_destroyed_respond} / {#on_destroyed_redirect_path} for that.
      # @yield Runs in the component's request context after `@data` was destroyed.
      # @return [void]
      # @api public
      def on_destroyed(&block)
        @on_destroyed_block = block
      end

      # DSL method
      # Overrides the response issued after a successful destroy. The default shows a flash and redirects to
      # {#on_destroyed_redirect_path} with HTTP 303 (forces a GET, required for Turbo). If you override this,
      # {#on_destroyed_redirect_path} is no longer called.
      # @yield Runs in the component's request context; expected to render or redirect.
      # @return [void]
      # @api public
      def on_destroyed_respond(&block)
        @on_destroyed_respond_block = block
      end

      # DSL method
      # Overrides the redirect target used by the default {#on_destroyed_respond} (keeping the default flash).
      # Defaults to the owner's Show (if owned) or the data's Index.
      # @yield Runs in the component's request context; expected to return a Rails path (e.g. via `Compony.path`).
      # @return [void]
      # @api public
      def on_destroyed_redirect_path(&block)
        @on_destroyed_redirect_path_block = block
      end

      # @!endgroup
    end
  end
end
