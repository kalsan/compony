module Compony
  module ComponentMixins
    module Default
      module Standalone
        class VerbDsl < Dslblend::Base
          AVAILABLE_VERBS = %i[get head post put delete connect options trace patch].freeze

          def initialize(component, verb)
            super()

            verb = verb.to_sym
            fail "Unknown HTTP verb #{verb.inspect}, use one of #{AVAILABLE_VERBS.inspect}" unless AVAILABLE_VERBS.include?(verb)

            @component = component
            @verb = verb
            @respond_blocks = { nil => proc { render_standalone(controller) } } # default format
            @authorize_block = nil
          end

          def to_conf(&)
            evaluate(&) if block_given?
            return {
              verb:            @verb,
              authorize_block: @authorize_block || proc { can?(comp_name.to_sym, family_name.to_sym) },
              respond_blocks:  @respond_blocks
            }.compact
          end

          protected

          # DSL
          # This block is expected to return true if and only if current_ability has the right to access the component over the given verb.
          def authorize(&block)
            @authorize_block = block
          end

          # DSL
          # This is the last step in the life cycle. It may redirect or render. If omitted, the default is standalone_render.
          # @param format [String, Symbol] Format this block should respond to, defaults to `nil` which means "all other formats".
          def respond(format = nil, &block)
            @respond_blocks[format&.to_sym] = block
          end
        end
      end
    end
  end
end
