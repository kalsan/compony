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

    # Renders a link to a component given a comp and model or family. If authentication is configured
    # and the current user has insufficient permissions to access the target object, the link is not displayed.
    # @param comp_name_or_cst [String,Symbol] The component that should be loaded, for instance `ShowForAll`, `'ShowForAll'` or `:show_for_all`
    # @param model_or_family_name_or_cst [String,Symbol,ApplicationRecord] Either the family that contains the requested component,
    #                                    or an instance implementing `model_name` from which the family name is auto-generated. Examples:
    #                                    `Users`, `'Users'`, `:users`, `User.first`
    # @param link_args [Array] Positional arguments that will be passed to the Rails `link_to` helper
    # @param label_opts [Hash] Options hash that will be passed to the label method (see {Compony::ComponentMixins::Default::Labelling#label})
    # @param link_kwargs [Hash] Named arguments that will be passed to the Rails `link_to` helper
    # TODO: Move much of the logic to Intent
    def compony_link(comp_name_or_cst_or_class,
                     model_or_family_name_or_cst = nil,
                     *link_args,
                     label: nil,
                     label_opts: {},
                     params: {},
                     feasibility_action: nil,
                     feasibility_target: nil,
                     standalone_name: nil,
                     **link_kwargs)
      model = model_or_family_name_or_cst.respond_to?(:model_name) ? model_or_family_name_or_cst : nil
      if comp_name_or_cst_or_class.is_a?(Class) && (comp_name_or_cst_or_class <= Compony::Component)
        target_comp_instance = comp_name_or_cst_or_class.new(data: model)
      else
        target_comp_instance = Compony.comp_class_for!(comp_name_or_cst_or_class, model_or_family_name_or_cst).new(data: model)
      end
      return unless target_comp_instance.standalone_access_permitted_for?(self, standalone_name:)
      feasibility_action ||= comp_name_or_cst_or_class.to_s.underscore.to_sym
      feasibility_target ||= model
      label ||= target_comp_instance.label(model, **label_opts)
      path ||= Compony.path(target_comp_instance.comp_name, target_comp_instance.family_name, model, standalone_name:, **params)
      if feasibility_target && !feasibility_target.feasible?(feasibility_action)
        path = '#'
        link_kwargs[:class] = link_kwargs[:class].is_a?(String) ? "#{link_kwargs[:class]} disabled" : 'disabled'
        link_kwargs[:title] = feasibility_target.full_feasibility_messages(feasibility_action).presence
      end
      return helpers.link_to(label, path, *link_args, **link_kwargs)
    end

    # Given a component and a family/model, this instanciates and renders a button component.
    # @see Compony#button Check Compony.button for accepted params
    # @see Compony::Components::Button Compony::Components::Button: the default underlying implementation
    def compony_button(...)
      Compony.button(...).render(helpers.controller)
    end
  end
end
