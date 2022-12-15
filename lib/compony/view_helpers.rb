module Compony
  # @api description
  # Methods in this module are available in content blocks and Rails views.
  # Rule of thumb: this holds methods that require a view context and results are rendered immediately.
  # @see Compony Compony for standalone/pure helpers
  module ViewHelpers
    # Use this in your application layout to render all actions of the current root component.
    def compony_actions
      return nil unless Compony.root_comp
      Compony.root_comp.render_actions(self, wrapper_class: 'root-actions', action_class: 'root-action')
    end

    # Generates a path to a component
    # @todo introduce params
    def compony_path(comp_name, family_name, ...)
      send("#{Compony.path_helper_name(comp_name, family_name)}_path", ...)
    end

    # Renders a link to a component given a comp and model or family. If authentication is configured
    # and the current user has insufficient permissions to access the target object, the link is not displayed.
    # @todo introduce params
    def compony_link(comp_name_or_cst, model_or_family_name_or_cst, *link_args, label_opts: {}, **link_kwargs)
      model = model_or_family_name_or_cst.respond_to?(:model_name) ? model_or_family_name_or_cst : nil
      comp = Compony.comp_class_for(comp_name_or_cst, model_or_family_name_or_cst).new(data: model)
      return unless comp.standalone_access_permitted_for?(self)
      return helpers.link_to(comp.label(model, **label_opts), compony_path(comp.comp_name, comp.family_name, model), *link_args, **link_kwargs)
    end

    # Renders a button component to a component given a comp and model or family
    # @todo introduce params
    def compony_button(...)
      Compony.button(...).render(helpers.controller)
    end
  end
end
