module Compony
  module ComponentMixins
    module Default
      module Standalone
        # @api description
        # Wrapper and DSL helper for component's standalone config
        # Pass `provide_defaults` true if this is the first standalone DSL of a component. Pass false if it is a subsequent one (e.g. if subclassed comp)
        class StandaloneDsl < Dslblend::Base
          def initialize(component, name = nil, provide_defaults:, path: nil, constraints: nil, scope: nil, scope_args: {})
            super()
            @component = component
            @name = name&.to_sym
            @provide_defaults = provide_defaults
            @path = path
            @constraints = constraints
            @scope = scope
            @scope_args = scope_args
            @verbs = {}
            # These default to nil so that, on subsequent `standalone` calls (e.g. subclass overrides), they are stripped
            # by `compact` and thus do NOT clobber values inherited via `deep_merge!`. The actual defaults are only injected
            # when `provide_defaults` is true (i.e. the first `standalone` call). This mirrors VerbDsl#to_conf.
            @skip_authentication = nil
            @skip_forgery_protection = nil
            @layout = nil # can be overriden by false or a string
          end

          # Defaults injected only on the first `standalone` call. Kept out of subsequent calls so inherited values survive.
          DEFAULT_CONFIG = {
            skip_authentication:     false,
            skip_forgery_protection: false,
            layout:                  true
          }.freeze

          # For internal usage only, processes the block and returns a config hash.
          def to_conf(&block)
            evaluate(&block)
            @component = block.binding.eval('self') # Fetches the component holding this DSL call (via the block)
            base_config = @provide_defaults ? DEFAULT_CONFIG.dup : {}
            return base_config.merge({
              name:                    @name,
              path:                    @path,
              constraints:             @constraints,
              scope:                   @scope,
              scope_args:              @scope_args,
              verbs:                   @verbs,
              rails_action_name:       rails_action_name(@name),
              path_helper_name:        path_helper_name(@name),
              skip_authentication:     @skip_authentication,
              skip_forgery_protection: @skip_forgery_protection,
              layout:                  @layout
            }.compact)
          end

          protected

          # DSL method. Defines the config for one HTTP verb. The block runs within the verb DSL; positional and named
          # arguments are forwarded to it. Call at most once per verb per standalone.
          # @param verb [Symbol] The HTTP verb (one of `:get :head :post :put :delete :connect :options :trace :patch`).
          # @return [void]
          # @api public
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

          # DSL method. Disables app authentication for this standalone (an `authorize` block is still mandatory).
          # @return [void]
          # @api public
          def skip_authentication!
            @skip_authentication = true
          end

          # DSL method. Disables forgery protection (CSRF) for this standalone's controller action.
          # @return [void]
          # @api public
          def skip_forgery_protection!
            @skip_forgery_protection = true
          end

          # DSL method. Sets the Rails layout (under `app/views/layouts`) used to render this component.
          # Defaults to Rails' default (`layouts/application`) if never called.
          # @param layout [String,Symbol] Layout name, as passed to a Rails controller's `render`.
          # @return [void]
          # @api public
          def layout(layout)
            @layout = layout.to_s
          end
        end
      end
    end
  end
end
