module Compony
  module ComponentMixins
    module Default
      module Standalone
        # @api description
        # DSL for speficying verb configs within a standalone config.
        # @see Compony::ComponentMixins::Default::Standalone::VerbDsl for the verb DSL for resourceful components
        # @see Compony::ComponentMixins::Default::Standalone::StandaloneDsl
        class VerbDsl < Dslblend::Base
          AVAILABLE_VERBS = %i[get head post put delete connect options trace patch].freeze

          def initialize(component, verb)
            super()

            verb = verb.to_sym
            fail "Unknown HTTP verb #{verb.inspect}, use one of #{AVAILABLE_VERBS.inspect}" unless AVAILABLE_VERBS.include?(verb)

            @component = component
            @verb = verb
            @respond_blocks = {}
            @authorize_block = nil
          end

          # For internal usage only, processes the block and returns a config hash.
          def to_conf(provide_defaults:, &)
            evaluate(&) if block_given?
            base_config = provide_defaults ? default_config : {}
            return base_config.deep_merge({
              verb:            @verb,
              authorize_block: @authorize_block,
              respond_blocks:  @respond_blocks
            }.compact)
          end

          protected

          # DSL
          # Mandatory. The block must return truthy iff `current_ability` may access the component over this verb;
          # a falsy result raises `CanCan::AccessDenied`.
          # @yield Runs in the component's request context; returns truthy to grant access.
          # @return [void]
          # @api public
          def authorize(&block)
            @authorize_block = block
          end

          # DSL
          # Last step in the lifecycle. May redirect or render. If omitted, the default is `render_standalone`.
          # NOTE: overriding `respond` replaces the default, which is where `authorize` is evaluated - re-check authorization yourself.
          # @param format [String,Symbol,nil] Format this block responds to; `nil` means "all other formats".
          # @yield Runs in the component's request context; renders or redirects.
          # @return [void]
          # @api public
          def respond(format = nil, &block)
            @respond_blocks[format&.to_sym] = block
          end

          # Internal, do not use
          def default_config
            return {
              authorize_block: proc { can?(comp_name.to_sym, family_name.to_sym) },
              respond_blocks:  { nil => proc { render_standalone(controller) } }
            }
          end
        end
      end
    end
  end
end
