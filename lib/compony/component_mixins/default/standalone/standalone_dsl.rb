module Compony
  module ComponentMixins
    module Default
      module Standalone
        # Wrapper and DSL helper for component's standalone config
        class StandaloneDsl < Dslblend::Base
          def initialize(name = nil, path: nil)
            super()
            @name = name&.to_sym
            @path = path
            @verbs = {}
            @skip_authentication = false
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
              skip_authentication: @skip_authentication
            }
          end

          protected

          # DSL
          def verb(verb, *args, **nargs, &block)
            verb = verb.to_sym
            @verbs[verb] ||= Compony::MethodAccessibleHash.new
            @verbs[verb].deep_merge! VerbDsl.new(verb, *args, **nargs).to_conf(&block)
          end

          # DSL
          def skip_authentication!
            @skip_authentication = true
          end
        end
      end
    end
  end
end
