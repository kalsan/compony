module Compony
  module ComponentMixins
    # Include this when your component's family name corresponds to the pluralized Rails model name the component's family is responsible for.
    # When including this, the component gets an attribute @data which contains a record or a collection of records.
    # To load or alter @data, always use the authorized_... methods defined below. Implement the actual operation in your component.
    module Resourceful
      extend ActiveSupport::Concern

      DEFAULT_LOAD_DATA_BLOCK = proc { @data = data_class.find(controller.params[:id]) }

      attr_reader :data

      def initialize(*args, data: nil, **nargs, &block)
        @data = data
        super(*args, **nargs, &block)
      end

      # DSL method
      # Sets or calculates the model class based on the component's family name
      def data_class(new_data_class = nil)
        @data_class ||= new_data_class || family_cst.to_s.singularize.constantize
      end

      # @override
      # Instanciate a component with `self` as a parent and render it
      def sub_comp(component_class, **comp_opts)
        comp_opts[:data] ||= data # Inject additional param before forwarding all of them to super
        super
      end
    end
  end
end
