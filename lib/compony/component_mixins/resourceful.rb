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

      def initialize(*args, data: nil, data_class: nil, **nargs, &block)
        @data = data
        @data_class = data_class

        # Provide defaults for hook blocks
        @global_load_data_block ||= proc { @data = self.data_class.find(controller.params[:id]) }

        super(*args, **nargs, &block)
      end

      # DSL method
      # Sets or calculates the model class based on the component's family name
      def data_class(new_data_class = nil)
        @data_class ||= new_data_class || family_cst.to_s.singularize.constantize
      end

      # Instanciate a component with `self` as a parent and render it, having it inherit the resource
      def resourceful_sub_comp(component_class, **comp_opts)
        comp_opts[:data] ||= data # Inject additional param before forwarding all of them to super
        comp_opts[:data_class] ||= data_class # Inject additional param before forwarding all of them to super
        sub_comp(component_class, **comp_opts)
      end

      def resourceful?
        return true
      end

      protected

      # DSL method
      # Sets a default load_data block for all standalone paths and verbs.
      # Can be overwritten for a specific path and verb in the
      # {Compony::ComponentMixins::Default::Standalone::VerbDsl}.
      # The block is expected to assign `@data`.
      # @see Compony::ComponentMixins::Default::Standalone::VerbDsl#load_data
      def load_data(&block)
        @global_load_data_block = block
      end

      # DSL method
      # Runs after loading data and before authorization for all standalone paths and verbs.
      # Example use case: if `load_data` produced an AR collection proxy, can still refine result here before `to_sql` is called.
      def after_load_data(&block)
        @global_after_load_data_block = block
      end

      # DSL method
      # Sets a default default assign_attributes block for all standalone paths and verbs.
      # Can be overwritten for a specific path and verb in the
      # {Compony::ComponentMixins::Default::Standalone::VerbDsl}.
      # The block is expected to assign suitable `params` to attributes of `@data`.
      # @see Compony::ComponentMixins::Default::Standalone::VerbDsl#assign_attributes
      def assign_attributes(&block)
        @global_assign_attributes_block = block
      end

      # DSL method
      # Runs after `assign_attributes` and before `store_data` for all standalone paths and verbs.
      # Example use case: prefilling some fields for a form
      def after_assign_attributes(&block)
        @global_after_assign_attributes_block = block
      end

      # DSL method
      # Sets a default store_data block for all standalone paths and verbs.
      # Can be overwritten for a specific path and verb in the
      # {Compony::ComponentMixins::Default::Standalone::VerbDsl}.
      # The block is expected save `@data` to the database.
      # @see Compony::ComponentMixins::Default::Standalone::VerbDsl#store_data
      def store_data(&block)
        @global_store_data_block = block
      end
    end
  end
end
