module Compony
  module Components
    module Buttons
      class CssButton < Link
        def prepare_opts!
          super
          css = [
            'display:inline-block',
            'padding:.15rem .35rem',
            'text-decoration:none',
            'border-radius:6px',
            'font-size: 13.333px'
          ]
          if @comp_opts[:class]&.split&.include?('disabled')
            css += [
              'background:#e9ecef',
              'color:#6c757d',
              'cursor: default'
            ]
          else
            css += [
              'background:#eaeaee',
              'color:#000000',
              'border:1px solid #90909e'
            ]
          end
          @comp_opts[:style] = "#{css.join(';')};"
        end
      end
    end
  end
end
