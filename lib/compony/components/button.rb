module Compony
  module Components
    # @api description
    # This is the default button implementation, providing a minimal button
    class Button < Compony::Component
      SUPPORTED_TYPES = %i[button submit].freeze

      def initialize(*args, label: nil, path: 'javascript:void(0)', method: nil, type: :button, enabled: true, visible: true, **kwargs, &block)
        if type != :button && !method.nil?
          fail("Param `method` is only allowed for :button type buttons, but got method #{method.inspect} for type #{type.inspect}")
        end

        @label = label
        @type = type.to_sym
        @path = path # If given a block, it will be evaluated in the helpers context when rendering
        @method = method || :get
        @enabled = enabled # can be boolean or block taking a controller returning a boolean
        @visible = visible

        fail "Unsupported button type #{@type}, use on of: #{SUPPORTED_TYPES.inspect}" unless SUPPORTED_TYPES.include?(@type)

        super(*args, **kwargs, &block)
      end

      setup do
        before_render do
          if @path.respond_to?(:call)
            @path = instance_exec(&@path)
          end
          if @enabled.respond_to?(:call)
            @enabled = @enabled.call(controller)
          end
          if @visible.respond_to?(:call)
            @visible = @visible.call(controller)
          end
          @path = 'javascript:void(0)' unless @enabled
        end

        content do
          if @visible
            case @type
            when :button
              concat button_to(@label, @path, method: @method, disabled: !@enabled)
            when :submit
              concat button_tag(@label, type: :submit, disabled: !@enabled)
            end
          end
        end
      end
    end
  end
end
