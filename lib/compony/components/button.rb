module Compony
  module Components
    # @api description
    # This is the default button implementation, providing a minimal button
    class Button < Compony::Component
      SUPPORTED_TYPES = %i[button submit].freeze

      # path: If given a block, it will be evaluated in the helpers context when rendering
      # enabled: If given a block, it will be evaluated in the helpers context when rendering
      def initialize(*, label: nil, path: nil, method: nil, type: nil, enabled: nil, visible: nil, title: nil, **, &)
        @label = label || Compony.button_defaults[:label]
        @type = type&.to_sym || Compony.button_defaults[:type] || :button
        @path = path || Compony.button_defaults[:path] || 'javascript:void(0)'
        @method = method || Compony.button_defaults[:method]
        if @type != :button && !@method.nil?
          fail("Param `method` is only allowed for :button type buttons, but got method #{@method.inspect} for type #{@type.inspect}")
        end
        @method ||= :get
        @enabled = enabled
        @enabled = Compony.button_defaults[:enabled] if @enabled.nil?
        @enabled = true if @enabled.nil?
        @visible = visible
        @visible = Compony.button_defaults[:visible] if @visible.nil?
        @visible = true if @visible.nil?
        @title = title || Compony.button_defaults[:title]

        fail "Unsupported button type #{@type}, use on of: #{SUPPORTED_TYPES.inspect}" unless SUPPORTED_TYPES.include?(@type)

        super(*, **, &)
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
              concat button_to(@label, @path, method: @method, disabled: !@enabled, title: @title)
            when :submit
              concat button_tag(@label, type: :submit, disabled: !@enabled, title: @title)
            end
          end
        end
      end
    end
  end
end
