module Compony
  module ModelFields
    # Use this as entrypoint instead of instanciating fields manually
    def self.build(name, model_class, type:, order_key:, auto_order_key:, filter_keys:, auto_filter_keys:)
      const = type.to_s.camelize
      Compony.model_field_namespaces.each do |model_field_namespace|
        model_field_namespace = model_field_namespace.constantize if model_field_namespace.is_a?(::String)
        if model_field_namespace.const_defined?(const, false)
          return model_field_namespace.const_get(const, false).new(name, model_class, order_key:, auto_order_key:, filter_keys:, auto_filter_keys:)
        end
      end
      fail("No `model_field_namespace` implements ...::#{const}. Configured namespaces: #{Compony.model_field_namespaces.inspect}")
    end
  end
end
