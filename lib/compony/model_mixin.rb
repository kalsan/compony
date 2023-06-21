module Compony
  module ModelMixin
    extend ActiveSupport::Concern

    included do
      class_attribute :fields, default: {}
      class_attribute :feasibility_preventions, default: {}
      class_attribute :primary_key_type_key, default: :integer

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
      # For virtual attributes, you must pass a type explicitely, otherwise it's auto-infered.
      def field(name, type, **extra_attrs)
        name = name.to_sym
        self.fields = fields.dup
        fields[name] = Compony.model_field_class_for(type.to_s.camelize).new(name, self, **extra_attrs)
      end

      # DSL method, sets the primary key type
      def primary_key_type(new_type)
        unless %i[integer string].include?(new_type.to_sym)
          fail("#{self} is declaring primary_key_type as #{new_type.inspect} but only :integer and :string are supported at this time.")
        end
        self.primary_key_type_key = new_type.to_sym
      end

      # DSL method, part of the Feasibility feature
      # Block must return `false` if the action should be prevented.
      def prevent(action_name, message, &block)
        self.feasibility_preventions = feasibility_preventions.dup # Prevent cross-class contamination
        feasibility_preventions[action_name.to_sym] ||= []
        feasibility_preventions[action_name.to_sym] << MethodAccessibleHash.new(action_name:, message:, block:)
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

    # Retrieves feasibility for the given instance
    # Calling this with an invalid action name will always return true.
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

    def feasibility_messages(action_name)
      action_name = action_name.to_sym
      feasible?(action_name) if @feasibility_messages&.[](action_name).nil? # If feasibility check hasn't been performed yet for this action, perform it now
      return @feasibility_messages[action_name]
    end

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
