module Compony
  module ComponentMixins
    module Default
      module Standalone
        class VerbDsl < Dslblend::Base
          AVAILABLE_VERBS = %i[get head post put delete connect options trace patch].freeze

          def initialize(verb)
            super()

            verb = verb.to_sym
            fail "Unknown HTTP verb #{verb.inspect}, use one of #{AVAILABLE_VERBS.inspect}" unless AVAILABLE_VERBS.include?(verb)

            @verb = verb
            @respond_blocks = { nil => proc { render_standalone(controller) } }
            @load_data_block = nil
            @accessible_block = nil
            @store_data_block = nil
          end

          def to_conf(&)
            evaluate(&)
            return {
              verb:             @verb,
              load_data_block:  @load_data_block,
              accessible_block: @accessible_block || proc { can?(comp_name.to_sym, family_name.to_sym) },
              store_data_block: @store_data_block,
              respond_blocks:   @respond_blocks
            }.compact
          end

          protected

          # DSL
          # This is the first step in the life cycle. If the block is provided, it is expected to assign something to @data.
          # This is used in resourceful components.
          def load_data(&block)
            @load_data_block = block
          end

          # DSL
          # This block is expected to return true if and only if current_ability has the right to access the component over the given verb.
          def accessible(&block)
            @accessible_block = block
          end

          # DSL
          # This is called after authorization. If the block is provided, it is expected to write back to the database.
          # This is used in resourceful components writing the DB.
          def store_data(&block)
            @store_data_block = block
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
