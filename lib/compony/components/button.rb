module Compony
  module Components
    # This is the default button implementation, providing a minimal button
    class Button < Compony::Component
      SUPPORTED_TYPES = %i[button submit].freeze

      def initialize(*args, label: nil, path: 'javascript:void(0)', html_options: {}, type: :button, enabled: true, visible: true, **kwargs, &block)
        @label = label
        @type = type.to_sym
        @path = path # If given a block, it will be evaluated in the helpers context when rendering
        default_html_options = type == :button ? { method: :get } : {}
        @html_options = default_html_options.merge(html_options)
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

          if @type == :submit && @html_options.keys.reject { |k| k == :data }.any?
            fail("Submit buttons only accept :data as html_options, but got: #{@html_options.pretty_inspect}")
          end
        end

        content do
          if @visible
            case @type
            when :button
              concat button_to(@label, @path, **@html_options, disabled: !@enabled)
            when :submit
              concat button_tag(@label, type: :submit, disabled: !@enabled)
            end
          end
        end
      end
    end
  end
end
