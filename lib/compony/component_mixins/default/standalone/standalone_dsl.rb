module Compony
  module ComponentMixins
    module Default
      module Standalone
        # @api description
        # Wrapper and DSL helper for component's standalone config
        class StandaloneDsl < Dslblend::Base
          def initialize(component, name = nil, path: nil)
            super()
            @component = component
            @name = name&.to_sym
            @path = path
            @verbs = {}
            @skip_authentication = false
            @layout = true # can be overriden by false or a string
          end

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

          # DSL
          def verb(verb, *args, **nargs, &)
            verb = verb.to_sym
            verb_dsl_class = @component.resourceful? ? ResourcefulVerbDsl : VerbDsl
            @verbs[verb] ||= Compony::MethodAccessibleHash.new
            @verbs[verb].deep_merge! verb_dsl_class.new(@component, verb, *args, **nargs).to_conf(&)
          end

          # DSL
          def skip_authentication!
            @skip_authentication = true
          end

          # DSL
          # Defaults to Rails' default (layouts/application)
          def layout(layout)
            @layout = layout.to_s
          end
        end
      end
    end
  end
end
