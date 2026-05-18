module Compony
  module ComponentMixins
    # Include this when your component's family name corresponds to the pluralized Rails model name the component's family is responsible for.
    # When including this, the component gets an attribute @data which contains a record or a collection of records.
    # Resourceful components are always aware of a data_class, corresponding to the expected @data.class and used e.g. to render lists or for `.new`.
    module Resourceful
      extend ActiveSupport::Concern

      attr_reader :data

      # Must prefix the following instance variables with global_ in order to avoid overwriting VerbDsl inst vars due to Dslblend.
      attr_reader :global_load_data_block
      attr_reader :global_after_load_data_block
      attr_reader :global_assign_attributes_block
      attr_reader :global_after_assign_attributes_block
      attr_reader :global_store_data_block

      def initialize(*, data: nil, data_class: nil, **nargs, &)
        @data = data
        @data_class = data_class

        # Provide defaults for hook blocks
        @global_load_data_block ||= proc { @data = self.data_class.find(controller.params[:id]) }

        super(*, **nargs, &)
      end

      # @!group DSL

      # DSL method
      # Sets or calculates the model class. Defaults to the component's family name, singularized and constantized.
      # @param new_data_class [Class,nil] If given, the model class to use (e.g. a {Compony::VirtualModel} subclass).
      # @return [Class] The resolved data class.
      # @api public
      def data_class(new_data_class = nil)
        @data_class ||= new_data_class || family_name.singularize.camelize.constantize
      end

      def resourceful?
        return true
      end

      protected

      # DSL method
      # Sets the default `load_data` block for all standalone paths and verbs (overridable per verb in the VerbDsl).
      # Runs before authorization. The block is expected to assign `@data`.
      # @yield Runs in the component's request context; must assign `@data`.
      # @return [void]
      # @api public
      # @see Compony::ComponentMixins::Default::Standalone::VerbDsl#load_data
      def load_data(&block)
        @global_load_data_block = block
      end

      # DSL method
      # Runs after `load_data` and before authorization for all standalone paths and verbs.
      # Example: refine an AR collection produced by `load_data` before it is read.
      # @yield Runs in the component's request context; may refine `@data`.
      # @return [void]
      # @api public
      def after_load_data(&block)
        @global_after_load_data_block = block
      end

      # DSL method
      # Sets the default `assign_attributes` block for all standalone paths and verbs (overridable per verb in the VerbDsl).
      # The block is expected to assign validated `params` to attributes of `@data`.
      # @yield Runs in the component's request context; assigns params onto `@data`.
      # @return [void]
      # @api public
      # @see Compony::ComponentMixins::Default::Standalone::VerbDsl#assign_attributes
      def assign_attributes(&block)
        @global_assign_attributes_block = block
      end

      # DSL method
      # Runs after `assign_attributes` and before `store_data` for all standalone paths and verbs.
      # Example: prefill or derive fields before validation.
      # @yield Runs in the component's request context; may mutate `@data`.
      # @return [void]
      # @api public
      def after_assign_attributes(&block)
        @global_after_assign_attributes_block = block
      end

      # DSL method
      # Sets the default `store_data` block for all standalone paths and verbs (overridable per verb in the VerbDsl).
      # The block is expected to persist `@data` (override e.g. for virtual models or custom persistence).
      # @yield Runs in the component's request context; persists `@data`.
      # @return [void]
      # @api public
      # @see Compony::ComponentMixins::Default::Standalone::VerbDsl#store_data
      def store_data(&block)
        @global_store_data_block = block
      end
    end
  end
end
