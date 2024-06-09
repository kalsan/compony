module Compony
  module ComponentMixins
    module Default
      module Standalone
        # @api description
        # Wrapper and DSL helper for component's standalone config
        # Pass `provide_defaults` true if this is the first standalone DSL of a component. Pass false if it is a subsequent one (e.g. if subclassed comp)
        class StandaloneDsl < Dslblend::Base
          def initialize(component, name = nil, provide_defaults:, path: nil)
            super()
            @component = component
            @name = name&.to_sym
            @provide_defaults = provide_defaults
            @path = path
            @verbs = {}
            @skip_authentication = false
            @layout = true # can be overriden by false or a string
          end

          # For internal usage only, processes the block and returns a config hash.
          def to_conf(&block)
            evaluate(&block)
            @component = block.binding.eval('self') # Fetches the component holding this DSL call (via the block)
            return {
              name:                @name,
              path:                @path,
              verbs:               @verbs,
              rails_action_name:   Compony.rails_action_name(comp_name, family_name, @name),
              path_helper_name:    Compony.path_helper_name(comp_name, family_name, @name),
              skip_authentication: @skip_authentication,
              layout:              @layout
            }.compact
          end

          protected

          # DSL call for defining a config for a verb. The block runs within the verb DSL, positional and named arguments are passed to the verb DSL.
          # @param verb [Symbol] The HTTP verb the config is for (e.g. :get, :post etc.)
          # @see Compony::ComponentMixins::Default::Standalone::VerbDsl
          def verb(verb, *, **nargs, &)
            verb = verb.to_sym
            verb_dsl_class = @component.resourceful? ? ResourcefulVerbDsl : VerbDsl
            if @verbs[verb]
              @verbs[verb].deep_merge! verb_dsl_class.new(@component, verb, *, **nargs).to_conf(provide_defaults: false, &)
            else
              # Note about provide_defaults:
              # - We must pass false if this is the second time `standalone` was called for this component -> see @provide_defaults
              # - We musst pass false if this is the second time `verb` was called for this component -> handled by the if statement (other branch)
              # - We must pass true otherwise (handled by this branch)
              @verbs[verb] = Compony::MethodAccessibleHash.new(
                verb_dsl_class.new(@component, verb, *, **nargs).to_conf(provide_defaults: @provide_defaults, &)
              )
            end
          end

          # DSL
          # Defines that for this component, no authentication should be performed.
          def skip_authentication!
            @skip_authentication = true
          end

          # DSL
          # Speficies the Rails layout (under `app/views/layouts`) that should be used to render this component.
          # Defaults to Rails' default (`layouts/application`) if the method is never called.
          # @param layout [String] name of the layout as you would give it to a Rails controller's `render` method
          def layout(layout)
            @layout = layout.to_s
          end
        end
      end
    end
  end
end
