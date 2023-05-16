module Compony
  module ComponentMixins
    module Default
      module Standalone
        # @api description
        # Verb DSL override specifically for resourceful components
        # @see Compony::ComponentMixins::Default::Standalone::VerbDsl
        # @see Compony::ComponentMixins::Resourceful
        class ResourcefulVerbDsl < VerbDsl
          def initialize(...)
            # All resourceful components have a load_data_block, which defaults to the one defined in Resource, defaulting to finding the record.
            @load_data_block = proc { evaluate_with_backfire(&@global_load_data_block) }
            super
          end

          # For internal usage only, processes the block and returns a config hash.
          def to_conf(&)
            return super.deep_merge({
                                      load_data_block:         @load_data_block,
                                      assign_attributes_block: @assign_attributes_block,
                                      store_data_block:        @store_data_block
                                    }).compact
          end

          protected

          # DSL
          # This is the first step in the life cycle. The block is expected to assign something to `@data`.
          def load_data(&block)
            @load_data_block = block
          end

          # DSL
          # This is called after `load_data`. The block is expected to assign data from `params` as attributes of `@data`.
          # If this method gets never called, the verb config will not contain a assign_attributes block.
          # If called without a block, the verb config will call the global_assign_attributes block defined in Resource.
          def assign_attributes(&block)
            if block_given?
              @assign_attributes_block = block
            else
              @assign_attributes_block = proc { evaluate_with_backfire(&@global_assign_attributes_block) }
            end
          end

          # DSL
          # This is called after authorization. The block is expected to write back to the database.
          # If this method gets never called, the verb config will not contain a store_data block.
          # If called without a block, the verb config will call the global_store_data block defined in Resource.
          def store_data(&block)
            if block_given?
              @store_data_block = block
            else
              @store_data_block = proc { evaluate_with_backfire(&@global_store_data_block) }
            end
          end
        end
      end
    end
  end
end
