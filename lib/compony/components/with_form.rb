module Compony
  module Components
    # @api description
    # This component is destined to take a sub-component that is a form component.
    # It can be called via :get or via `submit_verb` depending on whether its form should be shown or submitted.
    class WithForm < Component
      def initialize(...)
        @submit_path_block = proc { Compony.path(comp_name, family_name, @data) }
        @form_cancancan_action = :missing
        super
      end

      # Returns an instance of the form component responsible for rendering the form.
      # Feel free to override this in subclasses.
      def form_comp
        @form_comp ||= (form_comp_class || Compony.comp_class_for!(:form, family_name)).new(
          self,
          submit_verb:,
          # If applicable, Rails adds the route keys automatically, thus, e.g. :id does not need to be passed here, as it comes from the request.
          submit_path:      @submit_path_block,
          cancancan_action: form_cancancan_action
        )
      end

      # @!group DSL

      # DSL method
      # Sets or returns the HTTP verb the twinned form submits with (`:post` for New, `:patch` for Edit).
      # @param new_submit_verb [Symbol,nil] If given, sets the submit verb; must be a known HTTP verb.
      # @return [Symbol] The (possibly just set) submit verb.
      # @api public
      def submit_verb(new_submit_verb = nil)
        if new_submit_verb.present?
          new_submit_verb = new_submit_verb.to_sym
          available_verbs = ComponentMixins::Default::Standalone::VerbDsl::AVAILABLE_VERBS
          fail "Unknown HTTP verb #{new_submit_verb.inspect}, use one of #{available_verbs.inspect}" unless available_verbs.include?(new_submit_verb)
          @submit_verb = new_submit_verb
        end
        return @submit_verb || fail("WithForm component #{self} is missing a call to `submit_verb`.")
      end

      # DSL method
      # Overrides the Form component class instantiated by {#form_comp} (defaults to the same-family `Form`).
      # @param new_form_comp_class [Class,nil] The Form component class to use.
      # @return [Class,nil] The configured form component class.
      # @api public
      def form_comp_class(new_form_comp_class = nil)
        @form_comp_class ||= new_form_comp_class
      end

      # DSL method
      # Sets and gets the form's CanCanCan action, used for per-field `permitted_attributes`. Pass `nil` to disable per-field auth.
      # @param new_form_cancancan_action [Symbol,nil] The CanCanCan action (e.g. `:edit`); omit to read the current value.
      # @return [Symbol,nil] The configured CanCanCan action.
      # @api public
      def form_cancancan_action(new_form_cancancan_action = :missing)
        if new_form_cancancan_action != :missing
          @form_cancancan_action = new_form_cancancan_action
        end
        return @form_cancancan_action
      end

      # DSL method
      # Overrides the submit path, which otherwise defaults to this component's own path.
      # @yield [controller] Called with the controller; expected to return the Rails path the form submits to.
      # @return [void]
      # @api public
      def submit_path(&new_submit_path_block)
        @submit_path_block = new_submit_path_block
      end

      # @!endgroup
    end
  end
end
