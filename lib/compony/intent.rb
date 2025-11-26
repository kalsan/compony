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
    # @param name [Symbol] If given, will override the name of this intent. Defaults to component and family name joined by underscore.
    # @param label [String,Hash] If given, will be used for generating the label. If Hash, is given as options to {Intent#label}.
    # @param path [String,Hash] If given, will be used for generating the path. If Hash, is given as options to {Intent#path}.
    # @param data [ApplicationRecord,Object] If given, the target component will be instanciated with this argument. Omit if your second pos arg is a model.
    # @param data_class [Class] If given, the target component will be instanciated with this argument.
    # @param feasibility_target [ApplicationRecord] If given, will override the feasibility target (prevention framework)
    # @param feasibility_action [ApplicationRecord] If given, will override the feasibility action (prevention framework)
    def initialize(comp_name_or_cst_or_class,
                   model_or_family_name_or_cst = nil,
                   standalone_name: nil,
                   name: nil,
                   label: nil,
                   path: nil,
                   method: nil,
                   data: nil,
                   data_class: nil,
                   feasibility_target: nil,
                   feasibility_action: nil,
                   **custom_args)
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
      @name = name&.to_sym
      @standalone_name = standalone_name
      @label = label.is_a?(String) ? label : nil
      @label_opts = label.is_a?(Hash) ? label : {}
      @path = path.is_a?(String) ? path : nil
      @path_opts = path.is_a?(Hash) ? path : {}
      @method = method&.to_sym
      @feasibility_target = feasibility_target
      @feasibility_action = feasibility_action
      @custom_args = custom_args
    end

    # Returns true for things like User.first, but false for things like :users or User
    def model?
      @model = @data.respond_to?(:model_name) && !@data.is_a?(Class) if @model.nil?
      return @model
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
    def path(model = nil, *, standalone_name: nil, **path_opt_overrides)
      path_opts = @path_opts.deep_merge(path_opt_overrides)
      comp.path(model || (model? ? @data : nil), standalone_name: standalone_name || @standalone_name, **path_opts)
    end

    # Returns a name for this intent, consisting of comp and family name. Can be overriden in the constructor.
    # Example: :show_users, :destroy_sessions
    def name
      @name.presence || :"#{comp_class.comp_name}_#{comp_class.family_name}"
    end

    # Returns the label of buttons produced by this intent.
    def label(model = nil, *, **label_opt_overrides)
      label_opts = @label_opts.deep_merge(label_opt_overrides)
      @label.presence || comp.label(model || (model? ? @data : nil), *, **label_opts)
    end

    def method
      @method || :get
    end

    def feasibility_target
      @feasibility_target.presence || model? ? @data : nil
    end

    def feasibility_action
      @feasibility_action.presence || comp_class.comp_name.to_sym
    end

    # Returns whether this intent is feasible (no prevention)
    def feasible?
      return true if feasibility_target.blank? || feasibility_action.blank?
      return feasibility_target.feasible?(feasibility_action)
    end

    # Returns the options that are given to the initializer when creating a button from this intent.
    def button_comp_opts(label: {})
      return @custom_args.deep_merge({
                                       label:  label(**label),
                                       href:   feasible? ? path : nil,
                                       method:,
                                       class:  feasible? ? nil : 'disabled',
                                       title:  feasible? ? nil : feasibility_target.full_feasibility_messages(feasibility_action).presence
                                     })
    end

    def render(controller, parent_comp = nil, style: nil, label: {}, **button_comp_opts_overrides)
      # Check if permitted
      return nil unless comp.standalone_access_permitted_for?(controller, standalone_name: @standalone_name, verb: method)
      # Prepare opts
      button_comp_class ||= Compony.button_component_class(*[style].compact)
      button_opts = button_comp_opts(label:).merge(button_comp_opts_overrides)
      # Perform render
      if parent_comp
        return parent_comp.sub_comp(button_comp_class, **button_opts).render(controller)
      else
        button_comp_class.new(**button_opts).render(controller)
      end
    end
  end
end
