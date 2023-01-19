module Compony
  module ModelMixin
    extend ActiveSupport::Concern

    included do
      # TODO: The following class attribute initializations will likely not work for STI/inherited models as subclasses will probably influence superclasses.
      class_attribute :fields, default: {}
      class_attribute :field_groups, default: {}
      class_attribute :feasibility_preventions, default: {}
    end

    class_methods do
      # DSL method, defines a new field which will be translated and can be added to field groups
      # For virtual attributes, you must pass a type explicitely, otherwise it's auto-infered.
      def field(name, type)
        name = name.to_sym
        self.fields = fields.dup
        fields[name] = ModelFields::Field.new(name, self, type:)
      end

      # DSL method, defines a new field group
      def field_group(*names, inherit: nil, &block)
        inherit = field_groups[inherit] if inherit
        names.each do |name|
          name = name.to_sym
          self.field_groups = field_groups.dup
          new_field_group = ModelFields::FieldGroup.new(name, self, base_field_group: inherit)
          block.call(new_field_group)
          field_groups[name] = new_field_group
        end
      end

      # DSL method, part of the Feasibility feature
      # Block must return `false` if the action should be prevented.
      def prevent(action_name, message, &block)
        feasibility_preventions[action_name.to_sym] ||= []
        feasibility_preventions[action_name.to_sym] << MethodAccessibleHash.new.merge({ action_name:, message:, block: })
      end
    end

    # Retrieves feasibility for the given instance
    # Calling this with an invalid action name will always return true.
    def feasible?(action_name, recompute: false)
      action_name = action_name.to_sym
      @feasibility_messages ||= {}
      # Abort if check has already run and recompute is false
      if @feasibility_messages[action_name].nil? || recompute
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
      feasible? if @feasibility_messages[action_name].nil? # If feasibility check hasn't been performed yet for this action, perform it now
      return @feasibility_messages[action_name]
    end

    def full_feasibility_messages(action_name)
      return feasibility_messages(action_name).join(', ').capitalize
    end
  end
end
