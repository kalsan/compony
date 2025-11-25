# @api description
# Root module, containing confguration and pure helpers. For
# the setters, create an initializer `config/initializers/compony.rb` and call
# them from there.
# @see Compony::ViewHelpers Compony::ViewHelpers for helpers that require a view context and render results immediately
module Compony
  ##########=====-------
  # Configuration writers
  ##########=====-------

  # Adds a button style that can be referred to when rendering an intent.
  # @param name [Symbol] Name of the style. If it exists already, will override the style.
  # @param button_component_class [Class] Class of the button component that will be instanciated to render the intent.
  def self.register_button_style(name, button_component_class)
    unless button_component_class.is_a?(Class) && button_comp_class < Compony::Component
      fail("Expected a button component class, got #{button_component_class.inspect}")
    end
    @button_component_classes[name.to_sym] = button_component_class
  end

  # Setter for the default button style. Defaults to :css_button.
  # @param default_button_style [Symbol] Name of the style that should be used as default.
  # @see {Compony#default_button_style}
  def self.default_button_style=(default_button_style)
    @default_button_style = default_button_style
  end

  # Setter for the global field namespaces. This allows you to implement custom
  # Fields, be it new ones or overrides for existing Compony model fields.
  # Must give an array of strings of namespaces that contain field classes named after
  # the field type. The array is queried in order, if the first namespace does not
  # contain the class we're looking for, the next is considered and so on.
  # The classes defined in the namespace must inherit from Compony::ModelFields::Base
  # @param model_field_namespaces [Array] Array of strings, the names of the namespaces in the order they should be searched
  def self.model_field_namespaces=(model_field_namespaces)
    @model_field_namespaces = model_field_namespaces
  end

  # Setter for the name of the Rails `before_action` that should be called to
  # ensure that users are authenticated before accessing the component. For
  # instance, implement a method `def enforce_authentication` in your
  # `ApplicationController`. In the method, make sure the user has a session and
  # redirect to the login page if they don't. <br> The action must be accessible
  # by {ComponyController} and the easiest way to achieve this is to implement
  # the action in your `ApplicationController`. If this is never called,
  # authentication is disabled.
  # @param authentication_before_action [Symbol] Name of the method you want to call for authentication
  def self.authentication_before_action=(authentication_before_action)
    @authentication_before_action = authentication_before_action.to_sym
  end

  # Setter for a content block that runs before the root component gets rendered (standalone only). Usage is the same as `content`.
  # The block runs between `before_render` and `render`, i.e. before the first `content` block.
  def self.content_before_root_comp(&block)
    fail('`Compony.content_before` requires a block.') unless block_given?
    @content_before_root_comp_block = block
  end

  # Setter for a content block that runs after the root component gets rendered (standalone only). Usage is the same as `content`.
  # The block runs after `render`, i.e. after the last `content` block.
  def self.content_after_root_comp(&block)
    fail('`Compony.content_after` requires a block.') unless block_given?
    @content_after_root_comp_block = block
  end

  ##########=====-------
  # Configuration readers
  ##########=====-------

  # Getter for the button component class for a given style.
  # @param style [Symbol] Style for which the matching button component class should be returned. Defaults to {Compony.default_button_style}.
  # @see {Compony#register_button_style}
  # @see {Compony#default_button_style}
  def self.button_component_class(style = default_button_style)
    if @button_component_classes.nil?
      @button_component_classes = {
        css_button: Compony::Components::Buttons::CssButton,
        link:       Compony::Components::Buttons::Link
      }
    end
    @button_component_classes[style&.to_sym] || fail("Unknown button style #{style.inspect}. Use one of: #{@button_component_classes.keys.inspect}")
  end

  # Getter for the default button style, defaults to `:css_button`.
  # @see {Compony#default_button_style=}
  def self.default_button_style
    return @default_button_style || :css_button
  end

  # Getter for the global field namespaces.
  # @see Compony#model_field_namespaces= Explanation of model_field_namespaces (documented in the corresponding setter)
  def self.model_field_namespaces
    return @model_field_namespaces ||= ['Compony::ModelFields']
  end

  # Getter for the name of the Rails `before_action` that enforces authentication.
  # @see Compony#authentication_before_action= Explanation of authentication_before_action (documented in the corresponding setter)
  def self.authentication_before_action
    @authentication_before_action
  end

  # Getter for content_before_root_comp_block
  # @see Compony#content_before_root_comp=
  def self.content_before_root_comp_block
    @content_before_root_comp_block
  end

  # Getter for content_after_root_comp_block
  # @see Compony#content_after_root_comp=
  def self.content_after_root_comp_block
    @content_after_root_comp_block
  end

  ##########=====-------
  # Application-wide available pure helpers
  ##########=====-------

  # Pure helper to create a Compony Intent. If given an intent, will return it unchanged. Otherwise, will give all params to the intent initializer.
  def self.intent(intent_or_comp_args, ...)
    if intent_or_comp_args.is_a?(Intent)
      return intent_or_comp_args
    else
      return Intent.new(intent_or_comp_args, ...)
    end
  end

  # Generates a Rails path to a component. Examples: `Compony.path(:index, :users)`, `Compony.path(:show, User.first)`
  # The first two arguments are given to create an {Intent} and all subsequend args and all kwargs are given to {Intent#path}
  def self.path(comp_name_or_cst_or_class, model_or_family_name_or_cst = nil, ...)
    intent(comp_name_or_cst_or_class, model_or_family_name_or_cst).path(...)
  end

  # Given a component and a family/model, this returns the matching component class if any, or nil if the component does not exist.
  # @see Intent for allowed parameters.
  def self.comp_class_for(...)
    intent(...).comp_class
  end

  # Same as Compony#comp_class_for but fails if none found
  # @see Intent for allowed parameters.
  # @see Compony#comp_class_for
  def self.comp_class_for!(...)
    comp_class_for(...) || fail(
      "No component found for [#{comp_name_or_cst.inspect}, #{model_or_family_name_or_cst.inspect}]"
    )
  end

  # Given a component and a family/model, this instanciates and returns a button component.
  # @deprecated use {Compony#intent} instead.
  def self.button(*, label_opts: {}, **)
    Compony.button_component_class.new(**intent(*, **).button_comp_opts(label: label_opts))
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

  # Goes through model_field_namespaces and returns the first hit for the given constant
  # @param constant [Constant] The constant that is searched, e.g. RichText -> would return e.g. Compony::ModelFields::RichText
  def self.model_field_class_for(constant)
    model_field_namespaces.each do |model_field_namespace|
      model_field_namespace = model_field_namespace.constantize if model_field_namespace.is_a?(::String)
      if model_field_namespace.const_defined?(constant, false)
        return model_field_namespace.const_get(constant, false)
      end
    end
    fail("No `model_field_namespace` implements ...::#{constant}. Configured namespaces: #{Compony.model_field_namespaces.inspect}")
  end
end

require 'cancancan'
require 'dslblend'
require 'dyny'
require 'request_store'
require 'schemacop'
require 'simple_form'

require 'compony/intent'
require 'compony/engine'
require 'compony/model_fields/base'
require 'compony/model_fields/anchormodel'
require 'compony/model_fields/association'
require 'compony/model_fields/attachment'
require 'compony/model_fields/boolean'
require 'compony/model_fields/color'
require 'compony/model_fields/currency'
require 'compony/model_fields/date'
require 'compony/model_fields/datetime'
require 'compony/model_fields/decimal'
require 'compony/model_fields/email'
require 'compony/model_fields/float'
require 'compony/model_fields/integer'
require 'compony/model_fields/percentage'
require 'compony/model_fields/phone'
require 'compony/model_fields/rich_text'
require 'compony/model_fields/string'
require 'compony/model_fields/text'
require 'compony/model_fields/time'
require 'compony/model_fields/url'
require 'compony/component_mixins/default/standalone'
require 'compony/component_mixins/default/standalone/standalone_dsl'
require 'compony/component_mixins/default/standalone/verb_dsl'
require 'compony/component_mixins/default/standalone/resourceful_verb_dsl'
require 'compony/component_mixins/default/labelling'
require 'compony/component_mixins/resourceful'
require 'compony/exposed_intents_dsl'
require 'compony/component'
require 'compony/components/buttons/link'
require 'compony/components/buttons/css_button'
require 'compony/components/index'
require 'compony/components/list'
require 'compony/components/show'
require 'compony/components/form'
require 'compony/components/with_form'
require 'compony/components/new'
require 'compony/components/edit'
require 'compony/components/destroy'
require 'compony/method_accessible_hash'
require 'compony/natural_ordering'
require 'compony/model_mixin'
require 'compony/request_context'
require 'compony/version'
require 'compony/view_helpers'
require 'compony/controller_mixin'

if defined?(ActiveType::Object)
  require 'compony/virtual_model'
end
