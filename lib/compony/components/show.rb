module Compony
  module Components
    # @api description
    # This component is used for the Rails show paradigm.
    class Show < Compony::Component
      include Compony::ComponentMixins::Resourceful

      setup do
        standalone path: "/#{family_name}/:id", constraints: { id: /\d*/ } do
          verb :get do
            authorize { can?(:show, @data) }
          end
        end

        label(:long) { |data| data.label } # rubocop:disable Style/SymbolProc
        label(:short) { |_| I18n.t('compony.components.show.label.short') }
        icon { :eye }

        exposed_intents do
          if data_class.owner_model_attr
            add :show, @data.send(data_class.owner_model_attr), icon: :xmark, color: :secondary, label: I18n.t('compony.cancel')
          end

          if Compony.comp_class_for(:edit, family_name)
            add :edit, @data, label: { format: :short }
          end

          if Compony.comp_class_for(:destroy, family_name)
            add :destroy, @data, label: { format: :short }
          end
        end

        content :label do
          h2 component.label
        end

        content do
          content :data # Overwrite the main content block to wrap the data content block into e.g. a bootstrap card etc.
        end

        content :data, hidden: true do
          all_field_columns(@data) if @columns.none? # Default to showing everything

          table do
            thead do
              @columns.each do |column|
                value = instance_exec(@data, &column[:payload])
                next if value.nil?
                tr do
                  td column[:label]
                  td value, class: column[:class]
                end
              end
            end
          end
        end
      end

      # @param skip_columns [Array] Column names to be skipped in the case where this component is nested and therefore instanciated by a parent comp.
      def initialize(*, skip_columns: [], **)
        @columns = NaturalOrdering.new
        @skipped_columns = skip_columns.map(&:to_sym)
        super(*, **)
      end

      # Adds a column. The term column is for consistency with the List component and columns are typically model fields / attributes.
      # @param name [String,Symbol] The technical name of the attribute this column will be for.
      # @param label [nil,String] The human displayed label for this attribte. If nil, will consider `name` to be a field name and load the field's label.
      # @param class [nil,String] Extra CSS classes for the column's value.
      # @param link_opts [Hash] Options to pass to the `link_to` helper. Only used in the case of a field column that will produce a link (e.g. accociation).
      # @param link_to_component [Symbol] In the case a link is produced (e.g. association), defines the component the link points to. Detaults to `:show`.
      # @param block [Block] Custom code to run in order to provide the displayed value. Will be given the current record.
      def column(name, label: nil, class: nil, link_opts: {}, link_to_component: :show, **, &block)
        name = name.to_sym
        unless block_given?
          # Assume field column
          field = data_class.fields[name] || fail("Field #{name.inspect} was not found for data class #{data_class}")
          block = proc do |record|
            if controller.current_ability.permitted_attributes(:show, record).include?(field.name.to_sym)
              next field.value_for(record, link_to_component:, controller:, link_opts:).to_s
            else
              Rails.logger.debug { "Skipping show col #{field.name.inspect} because the current user is not allowed to perform show on #{data}." }
              nil
            end
          end
        end
        @columns.natural_push(name, block, label: label || field.label, class:, **)
      end

      # DSL method
      # Adds multiple columns that have identical kwargs, e.g. `class` (see `column`). Typically only used for bulk-adding model fields.
      # @param col_names [String] Names of the fields in `@data` that are to be added as attributes.
      def columns(*col_names, **)
        col_names.each { |col_name| column(col_name, **) }
      end

      # DSL method
      # Marks a column as skipped. Useful only when inheriting from a component that provides too many columns.
      # When nesting components and a column of a child `Show` component is to be skipped, use the constructor's `skip_columns` argument instead.
      # @param name [String] Name of the column to be skipped.
      def skip_column(name)
        @skipped_columns << name.to_sym
      end

      # DSL method
      # Goes through the fields of the given data and adds a field column for every field found.
      # @param data [ApplicationModel] Compony-enriched model that will be queried for fields.
      def all_field_columns(data)
        data.fields.each_key { |field_name| column(field_name) }
      end
    end
  end
end
