module Compony
  # This encapsulates useful methods for accessing data within a request.
  class RequestContext < Dslblend::Base
    # Allow explicit access to the controller object. All controller methods are delgated
    attr_reader :controller

    # include Pagy::Backend

    def initialize(component, controller, *additional_providers)
      # DSL provider is this class, controller is an additional provider, main provider should be the component
      # Note: we have to manually set the main provider here as the auto-detection sets it to the VerbDsl instance around the block,
      #       leading to undesired caching effects (e.g. components being re-used, even if the comp_opts have changed)
      super(controller.helpers, controller, *additional_providers, main_provider: component)
      @controller = controller
    end

    def evaluate_with_backfire(&block)
      evaluate(backfire_vars: true, &block)
    end

    def component
      @_main_provider
    end

    # Explicit accessor to this object. As Dslblend hides where a method comes from, this makes code modifying the request context more explicit.
    # This is for instance useful when a component wishes to extend the request context with a module in order to define methods directly on the context.
    def request_context
      self
    end
  end
end
