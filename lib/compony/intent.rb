module Compony
  # @api description
  # An Intent is a a gateway to a component, along with relevant context, such as the comp and family, perhaps a resource, standalone name, feasibility etc.
  # The class provides tooling used by various Compony helpers used to point to other components in some way.
  class Intent
    attr_reader :comp_class
    attr_reader :data

    # @param comp_name_or_cst_or_class [String,Symbol,Class] The component that should be loaded,
    #                                                        for instance `ShowForAll`, `'ShowForAll'` or `:show_for_all`,
    #                                                        or can also pass a component class (such as Components::Users::Show)
    # @param model_or_family_name_or_cst [String,Symbol,ApplicationRecord] Either the family that contains the requested component, or an
    #                                                                      instance implementing `model_name` from which the family name is auto-generated.
    #                                                                      Examples: `Users`, `'Users'`, `:users`, `User.first`
    # @param standalone_name [Symbol] If given, will override the standalone name for all `path` calls for this intent instance.
    # @param label [String,Callable] If given, will override the target component's label when generating links from this intent instance.
    # @param data [ApplicationRecord,Object] If given, the target component will be instanciated with this argument. Omit if your second pos arg is a model.
    # @param data_class [Class] If given, the garget component will be instanciated with this argument.
    def initialize(comp_name_or_cst_or_class, model_or_family_name_or_cst = nil, standalone_name: nil, label: nil, method: nil, data: nil, data_class: nil)
      # TODO: allow further arguments here (color, icon, ...), ideally make it extensible
      # TODO: Check if feasibility_target and feasibility_action are needed

      # Check for model / data
      @data = data
      @data ||= model_or_family_name_or_cst if model_or_family_name_or_cst.respond_to?(:model_name)
      @data_class = data_class

      # Figure out comp_class
      if comp_name_or_cst_or_class.is_a?(Class) && (comp_name_or_cst_or_class <= Compony::Component)
        # A class was given as the first argument
        @comp_class = comp_name_or_cst_or_class
      else
        # Build the constant from the first two arguments
        family_underscore_str = @data.respond_to?(:model_name) ? @data.model_name.plural : model_or_family_name_or_cst.to_s.underscore
        constant_str = "::Components::#{family_underscore_str.camelize}::#{comp_name_or_cst_or_class.to_s.camelize}"
        @comp_class = constant_str.constantize
      end

      # Store further arguments
      @standalone_name = standalone_name
      @label = label
      @method = method
    end

    # Returns true for things like User.first, but false for things like :users or User
    def model?
      @data.respond_to?(:model_name) && !@data.is_a?(Class)
    end

    # Instanciates the component and returns the instance. If `data` and/or `data_class` were specified when instantiating this intent, they are passed.
    # All given arguments will be given to the component's initializer, also overriding `data` and `data_class` if present.
    def comp(*, **)
      return @comp ||= @comp_class.new(*, data: @data, data_class: @data_class, **)
    end

    # Returns the path to the component.
    # Additional arguments are passed to the component's path block, which typically passes them to the Rails path helper.
    # @param model [ApplicationRecord] If given and non-nil, will override the model passed to the component's path block
    # @param standalone_name [Symbol] If given and non-nil, will override the `standalone_name` passed to the component's path block
    def path(model = nil, *, standalone_name: nil, **)
      comp.path(model || (model? ? @data : nil), **, standalone_name: standalone_name || @standalone_name, **)
    end
  end
end
