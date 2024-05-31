module Compony
  module ModelMixin
    extend ActiveSupport::Concern

    included do
      class_attribute :fields, default: {}
      class_attribute :feasibility_preventions, default: {}
      class_attribute :owner_model_attr

      class_attribute :autodetect_feasibilities_completed, default: false
    end

    class_methods do
      # This hook updates all fields from a subclass, making sure that fields point to correct model classes even in STI
      # e.g. in Parent: field :foo, ... omitted in child -> child.fields[:foo] should point to Child and not Parent.
      def inherited(subclass)
        super
        subclass.fields = subclass.fields.transform_values { |f| f.class.new(f.name, subclass, **f.extra_attrs) }
      end

      # DSL method, defines a new field which will be translated and can be added to field groups
      def field(name, type, **extra_attrs)
        name = name.to_sym
        self.fields = fields.dup
        field = Compony.model_field_class_for(type.to_s.camelize).new(name, self, **extra_attrs)
        # Register all fields that are not attributes yet
        if attribute_names.exclude?(field.name.to_s)
          attribute(name)
          if attribute_names.exclude?(field.name.to_s)
            fail "Cannot register attributes for #{self}: calling `attribute #{name.inspect}` has no effect. \
If this is an ActiveType object, consider placing `include ActiveModel::Attributes` at the top of the class."
          end
        end
        fields[name] = field
      end

      # DSL method, sets the containing model.
      # Use this when a model only makes sense within the context of another model and typically has no own index page.
      # For instance, a model LineItem that belongs_to :invoice would typically be owned_by :invoice.
      # Compony will automatically adjust Redirects and top actions.
      def owned_by(attribute_name)
        self.owner_model_attr = attribute_name.to_sym
      end

      # DSL method, part of the Feasibility feature
      # Block must return `false` if the action should be prevented.
      def prevent(action_names, message, &block)
        action_names = [action_names] unless action_names.is_a? Enumerable
        action_names.each do |action_name|
          self.feasibility_preventions = feasibility_preventions.dup # Prevent cross-class contamination
          feasibility_preventions[action_name.to_sym] ||= []
          feasibility_preventions[action_name.to_sym] << MethodAccessibleHash.new(action_name:, message:, block:)
        end
      end

      # DSL method, part of the Feasibility feature
      # Skips autodetection of feasibilities
      def skip_autodetect_feasibilities
        self.autodetect_feasibilities_completed = true
      end

      def autodetect_feasibilities!
        return if autodetect_feasibilities_completed
        # Add a prevention that reflects the `has_many` `dependent' properties. Avoids that users can press buttons that will result in a failed destroy.
        reflect_on_all_associations.select { |assoc| %i[restrict_with_exception restrict_with_error].include? assoc.options[:dependent] }.each do |assoc|
          prevent(:destroy, I18n.t('compony.feasibility.has_dependent_models', dependent_class: I18n.t(assoc.klass.model_name.plural.humanize))) do
            public_send(assoc.name).any?
          end
        end
        self.autodetect_feasibilities_completed = true
      end
    end

    # Retrieves feasibility for the given instance, returning a boolean indicating whether the action is feasibly.
    # Calling this with an invalid action name will always return true.
    # This also generates appropriate error messages for any reason causing it to return false.
    # Feasilbility is cached, thus the second access will be faster.
    # @param action_name [Symbol,String] the action that the feasibility should be checked for, e.g. :destroy
    # @param recompute [Boolean] whether feasibility should be forcably recomputed even if a cached result is present
    def feasible?(action_name, recompute: false)
      action_name = action_name.to_sym
      @feasibility_messages ||= {}
      # Abort if check has already run and recompute is false
      if @feasibility_messages[action_name].nil? || recompute
        # Lazily autodetect feasibilities
        self.class.autodetect_feasibilities!
        # Compute feasibility and gather messages
        @feasibility_messages[action_name] = []
        feasibility_preventions[action_name]&.each do |prevention|
          if instance_exec(&prevention.block)
            @feasibility_messages[action_name] << prevention.message
          end
        end
      end
      return @feasibility_messages[action_name].none?
    end

    # Retrieves feasibility for the given instance and returns an array of reasons preventing the feasibility. Returns an empty array if feasible.
    # Conceptually, this is comparable to a model's `errors`.
    # @param action_name [Symbol,String] the action that the feasibility should be checked for, e.g. :destroy
    def feasibility_messages(action_name)
      action_name = action_name.to_sym
      feasible?(action_name) if @feasibility_messages&.[](action_name).nil? # If feasibility check hasn't been performed yet for this action, perform it now
      return @feasibility_messages[action_name]
    end

    # Retrieves feasibility for the given instance and returns a string holding all reasons preventing the feasibility. Returns an empty string if feasible.
    # Messages are joined using commata. The first character is capitalized and a period is added to the end.
    # Conceptually, this is comparable to a model's `full_messages`.
    # @param action_name [Symbol,String] the action that the feasibility should be checked for, e.g. :destroy
    def full_feasibility_messages(action_name)
      text = feasibility_messages(action_name).join(', ').upcase_first
      text += '.' if text.present?
      return text
    end

    # Calls value_for on the desired field. Do not confuse with the static method field.
    def field(field_name, controller)
      fields[field_name.to_sym].value_for(self, controller:)
    end
  end
end
