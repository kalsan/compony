require 'active_support/concern'

module Compony
  module ComponentMixins
    module Default
      # api description
      # This module contains all methods for Component that concern labelling and look.
      module Labelling
        extend ActiveSupport::Concern

        # DSL method and accessor When assigning via DSL, pass format as first
        # parameter. When accessing the value, pass format as named parameter
        # (e.g. `format: :short`). <br/> A component either generates labels
        # without data (e.g. "New user") or with data (e.g. "Edit John Doe").
        # This needs to be consistent across all formats. If the block generates
        # labels with data, the label block must take exactly one argument,
        # otherwise none. Label blocks with data are given the data as argument.
        # The block is expected to return the label in the given format. <br/>
        # Examples:
        # - Setting a block with data: `label(:short){ |data| "Edit #{data.label}" }`
        # - Setting a block without data: `label(:short){ 'New user' }`
        # - Reading a component's label with data: `comp.label(User.first, format: :short)`
        # - Reading a component's label without data: `comp.label(format: :short)`
        def label(data_or_format = nil, format: :long, &block)
          format = data_or_format if block_given?
          format ||= :long
          format = format.to_sym

          if block_given?
            # Assignment via DSL
            if format == :all
              @label_blocks[:short] = block
              @label_blocks[:long] = block
            else
              @label_blocks[format] = block
            end
          else
            # Retrieval of the actual label
            fail('Label format :all may only be used for setting a label (with a block), not for retrieving it.') if format == :all
            label_block = @label_blocks[format] || fail("Format #{format} was not found for #{inspect}.")
            case label_block.arity
            when 0
              label_block.call
            when 1
              data_or_format ||= data
              if data_or_format.blank?
                fail "Label block of #{inspect} takes an argument, but no data was provided and a call to `data` did not return any data either."
              end
              label_block.call(data_or_format)
            else
              fail "#{inspect} has a label block that takes 2 or more arguments, which is unsupported."
            end
          end
        end

        # DSL method
        # Defines defaults for intents when rendering buttons. Just like in {label}, the block may be given a resource.
        # @param [Symbol] keyword The name of the keyword that should be given to the button by the intent if not overwritten
        # @param [Proc] block The block that, when called in the context of the component while rendering, returns the value for the arg given to the button.
        # @see {Compony::Component#button_defaults}
        def button(keyword, &block)
          fail("Please pass a block to `button` in #{inspect}.") unless block_given?
          @button_blocks ||= {}
          @button_blocks[keyword.to_sym] = block
        end

        # Executes and retrieves the button blocks
        # If this component is resourceful, give the block the resource. Expect the arity to match.
        # @param resource Pass the resource if and only if the component is resourceful.
        def button_defaults(resource = nil)
          return @button_blocks.to_h do |keyword, block|
            value = case block.arity
                    when 0
                      block.call
                    when 1
                      resource ||= data
                      if resource.blank?
                        fail("Button block #{keyword.inspect} of #{inspect} takes a resource, but none was provided and a call to `data` did not return any.")
                      end
                      block.call(resource)
                    else
                      fail "#{inspect} has a button block #{keyword.inspect} that takes 2 or more arguments, which is unsupported."
                    end
            next [keyword, value]
          end
        end

        private

        def init_labelling
          # Provide defaults
          @label_blocks = {
            long:  -> { "#{I18n.t(family_name.humanize)}: #{I18n.t(comp_name.humanize)}" },
            short: -> { I18n.t(comp_name.humanize) }
          }
          @button_blocks = {}
        end
      end
    end
  end
end
