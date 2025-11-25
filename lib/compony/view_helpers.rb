module Compony
  # @api description
  # Methods in this module are available in content blocks and Rails views.
  # Rule of thumb: this holds methods that require a view context and results are rendered immediately.
  # @see Compony Compony for standalone/pure helpers
  module ViewHelpers
    # Renders a link to a component given a comp and model or family. If authentication is configured
    # and the current user has insufficient permissions to access the target object, the link is not displayed.
    # @deprecated Use {RequestContext#render_intent} instead and pass `style: :link`.
    def compony_link(...)
      Compony.intent(...).render(helpers.controller, style: :link)
    end

    # Given a component and a family/model, this instanciates and renders a button component.
    # @deprecated Use {RequestContext#render_intent} instead.
    def compony_button(...)
      Compony.intent(...).render(helpers.controller)
    end
  end
end
