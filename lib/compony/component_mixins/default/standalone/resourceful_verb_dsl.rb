module Compony
  module ComponentMixins
    module Default
      module Standalone
        class ResourcefulVerbDsl < VerbDsl
          def to_conf(&)
            return super.deep_merge({
              load_data_block:  @load_data_block,
              store_data_block: @store_data_block
            }).compact
          end

          protected

          # DSL
          # This is the first step in the life cycle. If the block is provided, it is expected to assign something to @data.
          # This is used in resourceful components.
          def load_data(&block)
            @load_data_block = block
          end

          # DSL
          # This is called after authorization. If the block is provided, it is expected to write back to the database.
          # This is used in resourceful components writing the DB.
          def store_data(&block)
            @store_data_block = block
          end
        end
      end
    end
  end
end
