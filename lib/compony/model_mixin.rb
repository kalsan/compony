module Compony
  module ModelMixin
    extend ActiveSupport::Concern

    included do
      class_attribute :fields, default: {}
      class_attribute :field_groups, default: {}
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
      def field_group(name, inherit: nil, &block)
        name = name.to_sym
        self.field_groups = field_groups.dup
        inherit = field_groups[inherit] if inherit
        new_field_group = ModelFields::FieldGroup.new(name, self, base_field_group: inherit)
        block.call(new_field_group)
        field_groups[name] = new_field_group
      end
    end
  end
end
