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

  # Given a component and a family/model, this returns the matching component class if any
  # @param comp_name_or_cst [String,Symbol] The component that should be loaded, for instance `ShowForAll`, `'ShowForAll'` or `:show_for_all`
  # @param model_or_family_name_or_cst [String,Symbol,ApplicationRecord] Either the family that contains the requested component,
  #                                    or an instance implementing `model_name` from which the family name is auto-generated. Examples:
  #                                    `Users`, `'Users'`, `:users`, `User.first`
  def self.comp_class_for(comp_name_or_cst, model_or_family_name_or_cst)
    return ::Components.const_get(family_name_for(model_or_family_name_or_cst).camelize).const_get(comp_name_or_cst.to_s.camelize)
  end

  # Given a component and a family, this returns the name of the Rails URL helper returning the path to this component.<br>
  # The parameters are the same as for {Compony#rails_action_name}.<br>
  # Example usage: `send("#{path_helper_name(:index, :users)}_url)`
  # @see Compony::ViewHelpers#compony_path Prefer using view helper compony_path when a view context is available.
  # @see Compony#rails_action_name rails_action_name for the accepted params
  def self.path_helper_name(...)
    "#{rails_action_name(...)}_comp"
  end

  # Given a component and a family, this returns the name of the ComponyController action for this component.<br>
  # Optionally can pass a name for extra standalone configs.
  # @param comp_name_or_cst [String,Symbol] Name of the component the action points to.
  # @param model_or_family_name_or_cst [String,Symbol] Name of the family the action points to.
  # @param name [String,Symbol] If referring to an extra standalone entrypoint, specify its name using this param.
  # @see Compony::ViewHelpers#compony_path Prefer using view helper compony_path when a view context is available.
  def self.rails_action_name(comp_name_or_cst, model_or_family_name_or_cst, name = nil)
    [name.presence, comp_name_or_cst.to_s.underscore, family_name_for(model_or_family_name_or_cst)].compact.join('_')
  end

  # Given a component and a family/model, this instanciates and returns a button component.
  # @param comp_name_or_cst [String,Symbol] The component that should be loaded, for instance `ShowForAll`, `'ShowForAll'` or `:show_for_all`
  # @param model_or_family_name_or_cst [String,Symbol,ApplicationRecord] Either the family that contains the requested component,
  #                                    or an instance implementing `model_name` from which the family name is auto-generated. Examples:
  #                                    `Users`, `'Users'`, `:users`, `User.first`
  # @see Compony::ViewHelpers#compony_button View helper providing a wrapper for this method that immediately renders a button.
  # @todo introduce params
  def self.button(comp_name_or_cst, model_or_family_name_or_cst, label_opts: {}, params: {}, **override_kwargs)
    model = model_or_family_name_or_cst.respond_to?(:model_name) ? model_or_family_name_or_cst : nil
    target_comp_instance = Compony.comp_class_for(comp_name_or_cst, model_or_family_name_or_cst).new(data: model)
    options = {
      label:   target_comp_instance.label(model, **label_opts),
      icon:    target_comp_instance.icon,
      color:   target_comp_instance.color,
      path:    -> { compony_path(target_comp_instance.comp_name, target_comp_instance.family_name, model, **params) },
      visible: ->(controller) { target_comp_instance.standalone_access_permitted_for?(controller) }
    }.merge(override_kwargs.symbolize_keys)
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
      return model_or_family_name_or_cst.model_name.name.pluralize
    else
      return model_or_family_name_or_cst.to_s.underscore
    end
  end
end

# Require optional dependencies
# rubocop:disable Lint/SuppressedException
begin
  require 'cancancan'
rescue LoadError
end
# rubocop:enable Lint/SuppressedException

require 'request_store'
require 'dyny'
require 'simple_form'
require 'schemacop'
require 'dslblend'
require 'ransack'

require 'compony/engine'
require 'compony/model_fields/field'
require 'compony/model_fields/field_group'
require 'compony/model_fields/form_helper'
require 'compony/component_mixins/default/standalone'
require 'compony/component_mixins/default/standalone/standalone_dsl'
require 'compony/component_mixins/default/standalone/verb_dsl'
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
