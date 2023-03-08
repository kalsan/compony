# @api description
# Root module, containing confguration and pure helpers. For
# the setters, create an initializer `config/initializers/compony.rb` and call
# them from there.
# @see Compony::ViewHelpers Compony::ViewHelpers for helpers that require a view context and render results immediately
module Compony
  ##########=====-------
  # Configuration writers
  ##########=====-------

  # Setter for the global button component class. This allows you to implement a
  # custom button component and have all Compony button helpers use your custom
  # button component instead of {Compony::Components::Button}.
  # @param button_component_class [Class] Your custom button component class (inherit from {Compony::Components::Button} or {Compony::Component})
  def self.button_component_class=(button_component_class)
    @button_component_class = button_component_class
  end

  # Setter for the global form helper class. This allows you to implement a
  # custom form helper with additional features and have all form components use
  # it instead of the default {Compony::ModelFields::FormHelper}.
  def self.form_helper_class=(form_helper_class)
    @form_helper_class = form_helper_class
  end

  # Setter for the name of the Rails `before_action` that should be called to
  # ensure that users are authenticated before accessing the component. For
  # instance, implement a method `def enforce_authentication` in your
  # `ApplicationController`. In the method, make sure the user has a session and
  # redirect to the login page if they don't. <br> The action must be accessible
  # by {ComponyController} and the easiest way to achieve this is to implement
  # the action in your `ApplicationController`. If this is never called,
  # authentication is disabled.
  def self.authentication_before_action=(authentication_before_action)
    @authentication_before_action = authentication_before_action.to_sym
  end

  ##########=====-------
  # Configuration readers
  ##########=====-------

  # Getter for the global button component class.
  # @see Compony#button_component_class= Explanation of button_component_class (documented in the corresponding setter)
  def self.button_component_class
    @button_component_class ||= Components::Button
    @button_component_class = const_get(@button_component_class) if @button_component_class.is_a?(String)
    return @button_component_class
  end

  # Getter for the global form helper class.
  # @see Compony#form_helper_class= Explanation of form_helper_class (documented in the corresponding setter)
  def self.form_helper_class
    @form_helper_class ||= ModelFields::FormHelper
    @form_helper_class = const_get(@form_helper_class) if @form_helper_class.is_a?(String)
    return @form_helper_class
  end

  # Getter for the name of the Rails `before_action` that enforces authentication.
  # @see Compony#authentication_before_action= Explanation of authentication_before_action (documented in the corresponding setter)
  def self.authentication_before_action
    @authentication_before_action
  end

  ##########=====-------
  # Application-wide available pure helpers
  ##########=====-------

  # Generates a Rails path to a component. Examples: `Compony.path(:index, :users)`, `Compony.path(:show, User.first)`
  # @param comp_name_or_cst [String,Symbol] The component that should be loaded, for instance `ShowForAll`, `'ShowForAll'` or `:show_for_all`
  # @param model_or_family_name_or_cst [String,Symbol,ApplicationRecord] Either the family that contains the requested component,
  #                                    or an instance implementing `model_name` from which the family name is auto-generated. Examples:
  #                                    `Users`, `'Users'`, `:users`, `User.first`
  # @param args_for_path_helper [Array] Positional arguments passed to the Rails helper
  # @param kwargs_for_path_helper [Hash] Named arguments passed to the Rails helper. If a model is given to `model_or_family_name_or_cst`,
  #                                      the param `id` defaults to the passed model's ID.
  def self.path(comp_name_or_cst, model_or_family_name_or_cst, *args_for_path_helper, **kwargs_for_path_helper)
    # Extract model if any, to get the ID
    kwargs_for_path_helper.merge!(id: model_or_family_name_or_cst.id) if model_or_family_name_or_cst.respond_to?(:model_name)
    return Rails.application.routes.url_helpers.send(
      "#{path_helper_name(comp_name_or_cst, model_or_family_name_or_cst)}_path",
      *args_for_path_helper,
      **kwargs_for_path_helper
    )
  end

  # Given a component and a family/model, this returns the matching component class if any, or nil if the component does not exist.
  # @param comp_name_or_cst [String,Symbol] The component that should be loaded, for instance `ShowForAll`, `'ShowForAll'` or `:show_for_all`
  # @param model_or_family_name_or_cst [String,Symbol,ApplicationRecord] Either the family that contains the requested component,
  #                                    or an instance implementing `model_name` from which the family name is auto-generated. Examples:
  #                                    `Users`, `'Users'`, `:users`, `User.first`
  def self.comp_class_for(comp_name_or_cst, model_or_family_name_or_cst)
    family_cst_str = family_name_for(model_or_family_name_or_cst).camelize
    comp_cst_str = comp_name_or_cst.to_s.camelize
    return nil unless ::Components.const_defined?(family_cst_str)
    family_constant = ::Components.const_get(family_cst_str)
    return nil unless family_constant.const_defined?(comp_cst_str)
    return family_constant.const_get(comp_cst_str)
  end

  # As above but fails if none found
  def self.comp_class_for!(comp_name_or_cst, model_or_family_name_or_cst)
    comp_class_for(comp_name_or_cst, model_or_family_name_or_cst) || fail(
      "No component found for [#{comp_name_or_cst.inspect}, #{model_or_family_name_or_cst.inspect}]"
    )
  end

  # Given a component and a family, this returns the name of the Rails URL helper returning the path to this component.<br>
  # The parameters are the same as for {Compony#rails_action_name}.<br>
  # Example usage: `send("#{path_helper_name(:index, :users)}_url)`
  # @see Compony#path
  # @see Compony#rails_action_name rails_action_name for the accepted params
  def self.path_helper_name(...)
    "#{rails_action_name(...)}_comp"
  end

  # Given a component and a family, this returns the name of the ComponyController action for this component.<br>
  # Optionally can pass a name for extra standalone configs.
  # @param comp_name_or_cst [String,Symbol] Name of the component the action points to.
  # @param model_or_family_name_or_cst [String,Symbol] Name of the family the action points to.
  # @param name [String,Symbol] If referring to an extra standalone entrypoint, specify its name using this param.
  # @see Compony#path
  def self.rails_action_name(comp_name_or_cst, model_or_family_name_or_cst, name = nil)
    [name.presence, comp_name_or_cst.to_s.underscore, family_name_for(model_or_family_name_or_cst)].compact.join('_')
  end

  # Given a component and a family/model, this instanciates and returns a button component.
  # @param comp_name_or_cst [String,Symbol] The component that should be loaded, for instance `ShowForAll`, `'ShowForAll'` or `:show_for_all`
  # @param model_or_family_name_or_cst [String,Symbol,ApplicationRecord] Either the family that contains the requested component,
  #                                    or an instance implementing `model_name` from which the family name is auto-generated. Examples:
  #                                    `Users`, `'Users'`, `:users`, `User.first`
  # @param label_opts [Hash] Options hash that will be passed to the label method (see {Compony::ComponentMixins::Default::Labelling#label})
  # @param params [Hash] GET parameters to be inclued into the path this button points to. Special case: e.g. format: :pdf -> some.url/foo/bar.pdf
  # @param override_kwargs [Hash] Override button options, see options for {Compony::Components::Button}
  # @see Compony::ViewHelpers#compony_button View helper providing a wrapper for this method that immediately renders a button.
  # @see Compony::Components::Button Compony::Components::Button: the default underlying implementation
  # @todo add doc for feasibility
  def self.button(comp_name_or_cst,
                  model_or_family_name_or_cst,
                  label_opts: nil,
                  params: nil,
                  feasibility_action: nil,
                  feasibility_target: nil,
                  **override_kwargs)
    label_opts ||= button_defaults[:label_opts] || {}
    params ||= button_defaults[:params] || {}
    model = model_or_family_name_or_cst.respond_to?(:model_name) ? model_or_family_name_or_cst : nil
    target_comp_instance = Compony.comp_class_for!(comp_name_or_cst, model_or_family_name_or_cst).new(data: model)
    feasibility_action ||= button_defaults[:feasibility_action] || comp_name_or_cst.to_s.underscore.to_sym
    feasibility_target ||= button_defaults[:feasibility_target] || model
    options = {
      label:   target_comp_instance.label(model, **label_opts),
      icon:    target_comp_instance.icon,
      color:   target_comp_instance.color,
      path:    Compony.path(target_comp_instance.comp_name, target_comp_instance.family_name, model, **params),
      visible: ->(controller) { target_comp_instance.standalone_access_permitted_for?(controller) }
    }
    if feasibility_target
      options.merge!({
                       enabled: feasibility_target.feasible?(feasibility_action),
                       title:   feasibility_target.full_feasibility_messages(feasibility_action)
                     })
    end
    options.merge!(override_kwargs.symbolize_keys)
    return Compony.button_component_class.new(**options.symbolize_keys)
  end

  # Returns the current root component, if any
  def self.root_comp
    RequestStore.store[:compony_root_comp]
  end

  # Given a family name or a model-like class, this returns the suitable family name as String.
  # @param model_or_family_name_or_cst [String,Symbol,ApplicationRecord] Either the family that contains the requested component,
  #                                    or an instance implementing `model_name` from which the family name is auto-generated. Examples:
  #                                    `Users`, `'Users'`, `:users`, `User.first`
  def self.family_name_for(model_or_family_name_or_cst)
    if model_or_family_name_or_cst.respond_to?(:model_name)
      return model_or_family_name_or_cst.model_name.plural
    else
      return model_or_family_name_or_cst.to_s.underscore
    end
  end

  # Getter for current button defaults
  # @todo document params
  def self.button_defaults
    RequestStore.store[:button_defaults] || {}
  end

  # Overwrites the keys of the current button defaults by the ones provided during the execution of a given block and restores them afterwords.
  # @todo document params
  def self.with_button_defaults(**keys_to_overwrite, &block)
    # Lazy initialize butto_defaults store if it hasn't been yet
    RequestStore.store[:button_defaults] ||= {}
    keys_to_overwrite.transform_keys!(&:to_sym)
    old_values = {}
    newly_defined_keys = keys_to_overwrite.keys - RequestStore.store[:button_defaults].keys
    keys_to_overwrite.each do |key, new_value|
      # Assign new value
      old_values[key] = RequestStore.store[:button_defaults][key]
      RequestStore.store[:button_defaults][key] = new_value
    end
    return_value = block.call
    # Restore previous value
    keys_to_overwrite.each do |key, _new_value|
      RequestStore.store[:button_defaults][key] = old_values[key]
    end
    # Undefine keys that were not there previously
    newly_defined_keys.each { |key| RequestStore.store[:button_defaults].delete(key) }
    return return_value
  end
end

require 'cancancan'
require 'dslblend'
require 'dyny'
require 'ransack'
require 'request_store'
require 'schemacop'
require 'simple_form'

require 'compony/engine'
require 'compony/model_fields/field'
require 'compony/model_fields/field_group'
require 'compony/model_fields/form_helper'
require 'compony/component_mixins/default/standalone'
require 'compony/component_mixins/default/standalone/standalone_dsl'
require 'compony/component_mixins/default/standalone/verb_dsl'
require 'compony/component_mixins/default/standalone/resourceful_verb_dsl'
require 'compony/component_mixins/default/labelling'
require 'compony/component_mixins/resourceful'
require 'compony/component'
require 'compony/components/button'
require 'compony/components/form'
require 'compony/components/with_form'
require 'compony/components/resourceful/new'
require 'compony/components/resourceful/edit'
require 'compony/components/resourceful/destroy'
require 'compony/method_accessible_hash'
require 'compony/model_mixin'
require 'compony/request_context'
require 'compony/version'
require 'compony/view_helpers'
require 'compony/controller_mixin'
