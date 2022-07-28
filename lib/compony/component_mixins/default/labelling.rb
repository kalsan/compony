require 'active_support/concern'

module Compony
  module ComponentMixins
    module Default
      # This module contains all methods for Component that concern labelling and look
      module Labelling
        extend ActiveSupport::Concern

        # DSL method and accessor
        # When assigning via DSL, pass format as first parameter.
        # When accessing the value, pass foramt as named parameter
        def label(data_or_format = nil, format: :long, &block)
          format = data_or_format if block_given?
          fail("label format must be either :short or :long, but got #{format.inspect}") unless %i[short long].include?(format)
          format = format.to_sym

          if block_given?
            @label_blocks[format] = block
          elsif data_or_format.present?
            fail("#{inspect} does not support calling label with a subject instance.") unless @label_blocks[format].arity == 1
            @label_blocks[format].call(data_or_format)
          else
            fail("#{inspect} does not support calling label without a subject instance.") unless @label_blocks[format].arity == 0
            @label_blocks[format].call
          end
        end

        # DSL method and accessor
        def icon(&block)
          if block_given?
            @icon_block = block
          else
            @icon_block.call
          end
        end

        # DSL method and accessor
        def color(&block)
          if block_given?
            @color_block = block
          else
            @color_block.call
          end
        end

        private

        def init_labelling
          # Provide defaults
          @label_blocks = {
            long:  -> { "#{_(family_name.camelize)}: #{_(comp_name.camelize)}" },
            short: -> { _(comp_name.camelize).to_s }
          }
          @icon_block = -> { :'arrow-right' }
          @color_block = -> { :primary }
        end
      end
    end
  end
end
