module Compony
  module ModelMixin
    extend ActiveSupport::Concern

    included do
      class_attribute :attr_groups, default: {}
    end

    class_methods do
      def translated(**options)
        fail("Double call to translated in model #{inspect}") if @translation_options.present?
        default_options = {
          singular:    true,
          plural:      true,
          attr_groups: true
        }
        @translation_options = default_options.merge(options)
      end

      def translation_options
        @translation_options
      end

      def translated?
        @translation_options.present?
      end

      def attr_group(name, inherit: nil, &block)
        name = name.to_sym
        self.attr_groups = attr_groups.dup
        inherit = attr_groups[inherit] if inherit
        new_attr_group = AttrGroup.new(name, base_attr_group: inherit)
        block.call(new_attr_group)
        attr_groups[name] = new_attr_group
      end
    end
  end
end
