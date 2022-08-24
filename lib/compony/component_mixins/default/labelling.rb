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
            # Assignment via DSL
            @label_blocks[format] = block
          else
            # Retrieval of the actual label
            case @label_blocks[format].arity
            when 0
              @label_blocks[format].call
            when 1
              data_or_format ||= data
              if data_or_format.blank?
                fail "Label block of #{inspect} takes an argument, but no data was provided and a call to `data` did not return any data either."
              end
              @label_blocks[format].call(data_or_format)
            else
              fail "#{inspect} has a label block that takes 2 or more arguments, which is unsupported."
            end
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
            long:  -> { "#{I18n.t(family_name.humanize)}: #{I18n.t(comp_name.humanize)}" },
            short: -> { I18n.t(comp_name.humanize) }
          }
          @icon_block = -> { :'arrow-right' }
          @color_block = -> { :primary }
        end
      end
    end
  end
end
