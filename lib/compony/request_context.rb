module Compony
  # @api description
  # This encapsulates useful methods for accessing data within a request.
  class RequestContext < Dslblend::Base
    # Allow explicit access to the controller object. All controller methods are delgated.
    attr_reader :controller
    attr_reader :helpers
    attr_reader :local_assigns

    def initialize(component, controller, *additional_providers, helpers: nil, locals: {})
      # DSL provider is this class, controller is an additional provider, main provider should be the component
      # Note: we have to manually set the main provider here as the auto-detection sets it to the VerbDsl instance around the block,
      #       leading to undesired caching effects (e.g. components being re-used, even if the comp_opts have changed)
      @controller = controller
      @helpers = helpers || controller.helpers
      @local_assigns = locals.with_indifferent_access
      super(@helpers, @controller, *additional_providers, main_provider: component)
    end

    def evaluate_with_backfire(&)
      evaluate(backfire_vars: true, &)
    end

    def component
      @_main_provider
    end

    # Explicit accessor to this object. As Dslblend hides where a method comes from, this makes code modifying the request context more explicit.
    # This is for instance useful when a component wishes to extend the request context with a module in order to define methods directly on the context.
    def request_context
      self
    end

    # Provide access to local assigns as if it were a Rails context
    def method_missing(method, *args, **kwargs, &)
      return @local_assigns[method] if @local_assigns.key?(method)
      return super
    end

    def respond_to_missing?(method, include_all)
      return true if @local_assigns.key?(method)
      return super
    end
  end
end
