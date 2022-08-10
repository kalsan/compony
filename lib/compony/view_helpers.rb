module Compony
  module ViewHelpers
    def compony_root_comp
      RequestStore.store[:compony_root_comp]
    end

    # Use this in your application layout
    def compony_actions
      return nil unless compony_root_comp
      compony_root_comp.render_actions(self, wrapper_class: 'root-actions', action_class: 'root-action')
    end

    # Generates a path to a component
    def compony_path(comp_name, family_name, ...)
      comp_name = comp_name.to_s.underscore
      family_name = family_name.to_s.underscore
      send("#{Compony.path_helper_name(comp_name, family_name)}_path", ...)
    end

    # Renders a link to a component given a comp and model or family
    def compony_link(comp_name_or_cst, model_or_family_name_or_cst, ...)
      model = model_or_family_name_or_cst.respond_to?(:model_name) ? model_or_family_name_or_cst : nil
      comp = Compony.comp_class_for(comp_name_or_cst, model_or_family_name_or_cst).new(data: model)
      return unless comp.standalone_access_permitted_for?(self)
      return helpers.link_to(comp.label(model), compony_path(comp.comp_name, comp.family_name, model), ...)
    end

    # Renders a button component to a component given a comp and model or family
    def compony_button(...)
      Compony.button_comp(...).render(helpers.controller)
    end
  end
end
