module Compony
  # @api description
  # Methods in this module are available in content blocks and Rails views.
  # Rule of thumb: this holds methods that require a view context and results are rendered immediately.
  # @see Compony Compony for standalone/pure helpers
  module ViewHelpers
    # Renders a button/link to a component given a comp and model or family. If authentication is configured
    # and the current user has insufficient permissions to access the target object, the link is not displayed.
    # When inside a request context (`content do...`), this is preceded by {RequestContext#render_intent}.
    # @param button [Hash] Parameters that will be given to the button component initializer.
    def render_intent(*, button: {}, **)
      Compony.intent(*, **).render(self, **button)
    end
  end
end
