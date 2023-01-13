module Compony
  module ModelFields
    class FieldGroup
      attr_reader :name
      attr_reader :model_class
      attr_reader :fields

      def initialize(name, model_class, base_field_group: nil)
        @name = name.to_sym
        @model_class = model_class
        @fields = base_field_group&.fields&.dup || {}
      end

      def add(*field_names)
        field_names.each do |field_name|
          field_name = field_name.to_sym
          fail "FieldGroup #{name} already has an attribute #{field_name.to_sym.inspect}" if @fields.key?(field_name)
          @fields[field_name] = @model_class.fields[field_name] || fail("Missing field #{field_name} for #{@model_class.inspect}")
        end
      end

      def add_all
        @fields = @model_class.fields.dup
      end

      def del(*field_names)
        field_names.each do |field_name|
          field_name = field_name.to_sym
          fail "FieldGroup #{name} does not have an attribute #{field_name.to_sym.inspect}" unless @fields.key?(field_name)
          @fields.delete(field_name)
        end
      end

      # Used in form
      def form_helper_for(form, comp)
        Compony.form_helper_class.new(self, form, comp)
      end
    end
  end
end
