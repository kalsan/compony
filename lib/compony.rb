module Compony
  ##########=====-------
  # Configuration writers
  ##########=====-------

  def self.button_component_class=(button_component_class)
    @button_component_class = button_component_class
  end

  ##########=====-------
  # Configuration readers
  ##########=====-------

  def self.button_component_class
    @button_component_class ||= Components::Button
    @button_component_class = const_get(@button_component_class) if @button_component_class.is_a?(String)
    return @button_component_class
  end

  ##########=====-------
  # Application-wide available pure helpers
  ##########=====-------

  # Given a component and a family/model, this returns the matching component class if any
  def self.comp_class_for(comp_name_or_cst, model_or_family_name_or_cst)
    family_name_or_cst = model_or_family_name_or_cst
    if model_or_family_name_or_cst.respond_to?(:model_name)
      family_name_or_cst = model_or_family_name_or_cst.model_name.name.pluralize
    end
    return ::Components.const_get(family_name_or_cst.to_s.camelize).const_get(comp_name_or_cst.to_s.camelize)
  end

  # Given a component and a family, this returns the name of the Rails URL helper returning the path to this component.
  # Optionally can pass a name for extra paths.
  def self.action_name(comp_name, family_name, name = nil)
    [name.presence, "#{comp_name}_#{family_name}_comp"].compact.join('_')
  end

  # Given a component and a family/model, this instanciates and returns a button component.
  def self.button_comp(comp_name_or_cst, model_or_family_name_or_cst, **kwargs)
    model = model_or_family_name_or_cst.respond_to?(:model_name) ? model_or_family_name_or_cst : nil
    target_comp = Compony.comp_class_for(comp_name_or_cst, model_or_family_name_or_cst).new(data: model)
    return button_comp_for(target_comp, model, **kwargs)
  end

  # Given a component instance, this instanciates and returns a button component.
  def self.button_comp_for(target_comp_instance, model = nil, label_format: :long, **kwargs)
    options = {
      label:      target_comp_instance.label(model, format: label_format),
      icon:       target_comp_instance.icon,
      color:      target_comp_instance.color,
      path:       -> { compony_path(target_comp_instance.comp_name, target_comp_instance.family_name, model) },
      enabled_if: ->(controller) { target_comp_instance.standalone_access_permitted_for?(controller) }
    }.merge(kwargs.symbolize_keys)
    return Compony.button_component_class.new(**options.symbolize_keys)
  end

  # Raw method for producing a button
  def self.button(...)
    button_component_class.new(...)
  end
end

require 'compony/attr_group'
require 'compony/attr_group/attr'
require 'compony/attr_group/form_helper'
require 'compony/component_mixins/default/standalone'
require 'compony/component_mixins/default/standalone/standalone_dsl'
require 'compony/component_mixins/default/standalone/verb_dsl'
require 'compony/component_mixins/default/labelling'
require 'compony/component_mixins/resourceful'
require 'compony/component'
require 'compony/components/button'
require 'compony/components/form'
require 'compony/components/with_form'
require 'compony/method_accessible_hash'
require 'compony/model_mixin'
require 'compony/request_context'
require 'compony/version'
require 'compony/view_helpers'
require 'compony/controller_mixin'
require 'compony/railtie' if defined?(Rails::Railtie)