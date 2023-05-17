module Compony
  module ModelFields
    class Association < Base
      def initialize(...)
        super
        resolve_association!
      end

      def value_for(data, link_to_component: nil, link_opts: {}, controller: nil)
        if link_to_component
          fail('Must pass controller if link_to_component is given.') unless controller
          return transform_and_join(data.send(@name), controller:) do |el|
            el.nil? ? nil : controller.helpers.compony_link(link_to_component, el, **link_opts)
          end
        else
          return transform_and_join(data.send(@name), controller:) { |el| el&.label }
        end
      end

      def schema_line
        local_schema_key = @schema_key # Capture schema_key as it will not be available within the lambda
        if multi?
          return proc do
            ary? local_schema_key do
              list :integer, cast_str: true
            end
          end
        else
          return proc do
            int? local_schema_key, cast_str: true
          end
        end
      end

      def simpleform_input(form, _component, **input_opts)
        return form.association @name, **input_opts
      end

      protected

      # Uses Rails methods to figure out the arity, schema key etc. and store them.
      # This can be auto-inferred without accessing the database.
      def resolve_association!
        @association = true
        association_info = @model_class.reflect_on_association(@name) || fail("Association #{@name.inspect} does not exist for #{@model_class.inspect}.")
        @multi = association_info.macro == :has_many
        id_name = "#{@name.to_s.singularize}_id"
        @schema_key = @multi ? id_name.pluralize.to_sym : id_name.to_sym
      rescue ActiveRecord::NoDatabaseError
        Rails.logger.warn('Warning: Compony could not auto-detect fields due to missing database. This is ok when running db:create.')
      end
    end
  end
end
