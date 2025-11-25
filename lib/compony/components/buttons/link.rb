module Compony
  module Components
    module Buttons
      class Link < Component
        setup do
          before_render do
            prepare_opts!
          end

          content do
            concat link_to(@label, @href, **@comp_opts)
          end
        end

        protected

        def prepare_opts!
          @label = @comp_opts.delete(:label).presence
          @href = @comp_opts.delete(:href).presence || 'javascript:void(0)'
          @method = @comp_opts.delete(:method).presence
          if @method && @method.to_sym != :get
            @comp_opts[:data] = { turbo_method: @method }.merge(@comp_opts[:data] || {})
          end
          if @comp_opts[:class]&.split&.include?('disabled')
            @comp_opts[:style] = 'text-decoration:line-through;cursor: default;color: #6c757d;'
          end
        end
      end
    end
  end
end
