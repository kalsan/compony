module Compony
  module ComponentMixins
    # Include this when your component's family name corresponds to the pluralized Rails model name the component's family is responsible for.
    # When including this, the component gets an attribute @data which contains a record or a collection of records.
    # Resourceful components are always aware of a data_class, corresponding to the expected @data.class and used e.g. to render lists or for `.new`.
    module Resourceful
      extend ActiveSupport::Concern

      class_methods do
        # Overrides default resourceful? method. Used to find resourceful components.
        # Do not override.
        def resourceful?
          true
        end
      end

      attr_reader :data

      def initialize(*args, data: nil, data_class: nil, **nargs, &block)
        @data = data
        @data_class = data_class
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

      protected

      # DSL method
      # Overrides the default_load_data_block.
      # In resourceful containers, the load_data block in a standalone container defaults to `default_load_data_block`,
      #    which in turn defaults to just loading the appropriate object given by the ID param. This is intended to be overridden as follows:
      #    - Template components can override it to provide a different base functionality
      #      (e.g. if you implement a `Resourceful::Index` base component, you may want to load something like `data_class.all``)
      #    - Specific components can override that again to provide a query specific to their model. In the same example, you may want to use a scope
      #      specic to the model you are loading in your model-specific Index component, e.g. `Users::Index`: `User.nondeleted.includes(:user_meta)`
      #    - When speficying extra standalone verbs, you may want to speficy your own `load_data_block` depending on your use case. To mimic the behavior
      #      of the default standalone config, call the `default_load_data_block`.
      def default_load_data(&block)
        @default_load_data_block = block
      end

      def default_load_data_block
        @default_load_data_block ||= proc { @data = data_class.find(controller.params[:id]) } # this is the default default load_data block ;-)
      end
    end
  end
end
