module Compony
  module Components
    module Buttons
      class Link < Component
        # Legacy value of `@href` when no `href` was given. {#link_or_button} renders an `<a>` without `href` in this case. The value only
        # remains so that button styles that still call `link_to(@href, ...)` themselves keep their former markup until they render
        # through {#link_or_button}. A `javascript:` URL violates any Content Security Policy that does not allow inline scripts.
        NO_HREF = 'javascript:void(0)'.freeze

        setup do
          before_render do
            prepare_opts!
          end

          content do
            concat link_or_button
          end
        end

        def render(...)
          html = super
          if html && @type && !@link_or_button_rendered
            fail "#{self.class} was given `type: #{@type.inspect}` but did not render through `link_or_button`, so it rendered a link instead " \
                 'of a <button>. Render the element with `component.link_or_button(...)` in the content block instead of `link_to`.'
          end
          return html
        end

        # Renders the HTML element of this button:
        # - a `<button>` of the given type if `type:` was given (e.g. `:submit` for a form's submit button),
        # - an `<a>` without `href` if no `href` was given (clicking it does nothing, and it needs no JavaScript),
        # - a regular link otherwise.
        # Button styles that override `content` must render through this method rather than calling `link_to(@href, ...)` themselves.
        # @param inner_html [String] Content of the element, defaults to the label. To pass markup, use e.g. `capture { span 'x' }`.
        # @param html_opts [Hash] HTML attributes of the element, defaults to the button's options left after `prepare_opts!`.
        def link_or_button(inner_html = @label, html_opts = @comp_opts)
          @link_or_button_rendered = true
          helpers = ActionController::Base.helpers
          if @type
            disabled = html_opts[:disabled] || html_opts[:class]&.split&.include?('disabled')
            return helpers.content_tag(:button, inner_html, **html_opts, type: @type, disabled:)
          elsif @href == NO_HREF
            return helpers.content_tag(:a, inner_html, **html_opts)
          else
            return helpers.link_to(inner_html, @href, **html_opts)
          end
        end

        protected

        def prepare_opts!
          @label = @comp_opts.delete(:label).presence
          @href = @comp_opts.delete(:href).presence || NO_HREF
          @type = @comp_opts.delete(:type).presence&.to_sym
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
