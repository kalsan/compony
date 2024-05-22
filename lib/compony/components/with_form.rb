module Compony
  module Components
    # @api description
    # This component is destined to take a sub-component that is a form component.
    # It can be called via :get or via `submit_verb` depending on whether its form should be shown or submitted.
    class WithForm < Component
      def initialize(...)
        # TODO: On the next line, use Compony.path instead? Likely, this was implemented before that method existed.
        @submit_path_block = ->(controller) { controller.helpers.send("#{Compony.path_helper_name(comp_name, family_name)}_path") }
        super
      end

      # Returns an instance of the form component responsible for rendering the form.
      # Feel free to override this in subclasses.
      def form_comp
        @form_comp ||= (form_comp_class || Compony.comp_class_for!(:form, family_cst)).new(
          self,
          submit_verb:,
          # If applicable, Rails adds the route keys automatically, thus, e.g. :id does not need to be passed here, as it comes from the request.
          submit_path: @submit_path_block
        )
      end

      # DSL method
      # Sets or returns the previously set submit verb
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
      # Overrides the form comp class that is instanciated to render the form
      def form_comp_class(new_form_comp_class = nil)
        @form_comp_class ||= new_form_comp_class
      end

      # DSL method
      # Overrides the submit path which would otherwise default to this component
      # This takes a block that will be called and given a controller
      def submit_path(&new_submit_path_block)
        @submit_path_block = new_submit_path_block
      end
    end
  end
end
