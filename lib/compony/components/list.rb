module Compony
  module Components
    # @api description
    # This component is used for the Rails list paradigm. It is meant to be nested inside the same family's `::Index` or an owner's `::Show` component.
    class List < Compony::Component
      include Compony::ComponentMixins::Resourceful

      # The following parameters are meant for the case where this component is nested and therefore instanciated by a parent comp.
      # If the component is to configure itself, use the DSL calls below instead.
      # @param skip_pagination [Boolean] Disables pagination (caution: all records will be loaded)
      # @param results_per_page [Integer] In case pagination is active, defines the amount of records to display per page.
      # @param skip_filtering [Boolean] Disables filtering entirely (sorting is independent of this setting).
      # @param skip_sorting [Boolean] Disables sorting entirely (both links and sorting input in filter).
      # @param skip_sorting_in_filter [Boolean] Disables sorting in filter.
      # @param skip_sorting_links [Boolean] Disables sorting links.
      # @param skip_columns [Array] Column names to be skipped.
      # @param skip_row_actions [Array] Row action names to be skipped.
      # @param skip_filters [Array] Filter names to be skipped.
      # @param default_sorting [String] Default sorting (only relevant for ransack based sorting)
      def initialize(*,
                     skip_pagination: false,
                     results_per_page: 20,
                     skip_filtering: false,
                     skip_sorting: false,
                     skip_sorting_in_filter: false,
                     skip_sorting_links: false,
                     skip_columns: [],
                     skip_row_actions: [],
                     skip_filters: [],
                     default_sorting: 'id asc',
                     **)
        @pagination = !skip_pagination
        @results_per_page = results_per_page
        @filtering = !skip_filtering
        @sorting_in_filter = !skip_sorting && !skip_sorting_in_filter
        @sorting_links = !skip_sorting && !skip_sorting_links
        @columns = Compony::NaturalOrdering.new
        @row_actions = Compony::NaturalOrdering.new
        @skipped_columns = skip_columns.map(&:to_sym)
        @skipped_row_actions = skip_row_actions.map(&:to_sym)
        @filters = Compony::NaturalOrdering.new
        @sorts = Compony::NaturalOrdering.new
        @skipped_filters = skip_filters.map(&:to_sym)
        @default_sorting = default_sorting
        @filter_label_class = 'list-filter-label'
        @filter_input_class = 'list-filter-input'
        @filter_select_class = 'list-filter-select'
        @filter_item_wrapper_class = nil
        super(*, **)
      end

      # DSL method
      # Disables pagination (caution: all records will be loaded).
      def skip_pagination!
        @pagination = false
      end

      # DSL method
      # In case pagination is active, defines the amount of records to display per page.
      def results_per_page(new_results_per_page)
        @results_per_page = new_results_per_page
      end

      # DSL method
      # Disables filtering entirely (sorting is independent of this setting).
      def skip_filtering!
        @filtering = false
      end

      # DSL method
      # Disables sorting entirely (both links and sorting input in filter).
      def skip_sorting!
        @sorting_in_filter = false
        @sorting_links = false
      end

      # DSL method
      # Disables sorting in filter.
      def skip_sorting_in_filter!
        @sorting_in_filter = false
      end

      # DSL method
      # Disables sorting links.
      def skip_sorting_links!
        @sorting_links = false
      end

      # DSL method
      # Overrides the default sorting
      def default_sorting(new_default_sorting)
        @default_sorting = new_default_sorting
      end

      # DSL method
      # Sets the CSS class attribute for form label elements in filters.
      # @param class_str [String] Space-separated list of CSS classes
      def filter_label_class(class_str)
        @filter_label_class = class_str
      end

      # DSL method
      # Sets the CSS class attribute for string form inputs in filters.
      # @param class_str [String] Space-separated list of CSS classes
      def filter_input_class(class_str)
        @filter_input_class = class_str
      end

      # DSL method
      # Sets the CSS class attribute for form select inputs in filters.
      # @param class_str [String] Space-separated list of CSS classes
      def filter_select_class(class_str)
        @filter_select_class = class_str
      end

      # DSL method
      # Sets the CSS class attribute for the div that wraps input-related elements in filters (inputs, selects, labels).
      # @param class_str [String] Space-separated list of CSS classes
      def filter_item_wrapper_class(class_str)
        @filter_item_wrapper_class = class_str
      end

      # DSL method
      # Adds a new column to the list. If `name` corresponds to that of a field, everything is auto-inferred.
      # Custom columns can be added by providing at least `label` and a block that will be given a record and instance-execed for every row.
      # Please note that the column is only shown if the current user has permission to index the attribute.
      # @param name [String] Name of the field that is supposed to be displayed. If custom name, make sure the user has the permission to index the attribute.
      # @param label [String] Title of the column to be displayed in the table header.
      # @param class [String] Space-separated list of CSS classes for each cell
      # @param link_opts [Hash] Only used in the case of a model field, this is used to pass options to the field's `value_for`.
      # @param block [Block] Custom block, given the record and instance-execed in the context of the cell for every row.
      def column(name, label: nil, class: nil, link_opts: {}, **, &block)
        name = name.to_sym
        unless block_given?
          # Assume field column
          field = data_class.fields[name] || fail("Field #{name.inspect} was not found for data class #{data_class}")
          block = proc do |record|
            if controller.current_ability.permitted_attributes(:index, record).include?(field.name.to_sym)
              next field.value_for(record, link_to_component: :show, controller:, link_opts:).to_s
            end
          end
        end
        @columns.natural_push(name, block, label: label || field.label, class:, **)
      end

      # DSL method
      # Adds multiple columns at once, sharing the same kwargs.
      def columns(*col_names, **)
        col_names.each { |col_name| column(col_name, **) }
      end

      # DSL method
      # Marks a single column as skipped. It will not be displayed, even if it is defined.
      # @param name [Symbol,String] Name of the column to be skipped.
      def skip_column(name)
        @skipped_columns << name.to_sym
      end

      # DSL method
      # Adds a row action. The very last col provides actions such as :show, :edit or :destroy. Use this method to add your own.
      # In case the action exists as a component in the family of `data_class`, it is enough to pass the action's name, and the rest is auto-generated.
      # In order to create a custom row action, pass a block that will be given the current record and instance-execed once per row, for every record.
      # @param name [Symbol, String] The name of the action (e.g. :edit).
      # @param button_opts [Hash] Only relevant in case of an auto-generated row action, this allows to configure the generated button.
      # @param block [Block] To create a custom row action; block will be given the current record and instance-execed once per row, for every record.
      def row_action(name, button_opts: {}, **, &block)
        name = name.to_sym
        unless block_given?
          block = proc do |record|
            next if Compony.comp_class_for(name, record).nil?
            render_intent(name, record, **{ label: { format: :short } }.deep_merge(button_opts))
          end
        end
        @row_actions.natural_push(name, block, **)
      end

      # DSL method
      # Marks a single row action as skipped. It will not be displayed, even if it is defined.
      # @param name [Symbol,String] Name of the row action to be skipped.
      def skip_row_action(name)
        @skipped_row_actions << name.to_sym
      end

      # DSL method
      # Adds a ransack filter. If `name` is the name of an existing model field, the filter is auto-generated.
      # If `name` is a valid Ransack search string (e.g. `id_eq`), all you need to pass is `name` and `label`.
      # To create a fully custom filter, pass `name` and `block`. The block will be given the Ransack search form and should return HTML.
      # @param name [String] The name of the filter. Can either be the name of a field, a ransack search string or a custom name (see above).
      # @param label [String] The text to use in the input's label.
      # @param block [Block] Custom block that will be given the Ransack search form and should produce a label and a search input.
      def filter(name, label: nil, **, &block)
        name = name.to_sym
        unless block_given?
          field = data_class.fields[name]
          block ||= proc do |f|
            label ||= field.label if field
            fail("You must provide a label to filter #{name.inspect}.") unless label

            if field
              filter_name = field.ransack_filter_name
              filter_input_html = capture { field.ransack_filter_input(f, filter_input_class: @filter_input_class, filter_select_class: @filter_select_class) }
            else
              filter_name = name
              filter_input_html = capture { f.search_field(filter_name, class: @filter_input_class) }
            end
            div tag.label(label, for: filter_name, class: @filter_label_class), class: @filter_item_wrapper_class
            div filter_input_html, class: @filter_item_wrapper_class
          end
        end

        @filters.natural_push(name, block, **)
      end

      # DSL method
      # Adds multiple filters at once, sharing the same kwargs.
      def filters(*filter_names, **)
        filter_names.each { |filter_name| filter(filter_name, **) }
      end

      # DSL method
      # Adds a sorting criterion that will be processed by ransack. `data_class` must be sortable by this criterion. See Ransack's sorting for constraints.
      # For every call of this method, one sorting link and two entries (asc, desc) in the sorting-in-filter feature will be generated, if enabled.
      # @param name [Symbol, String] Sorting criteria, e.g. `:id` or `:label`.
      # @param label [String] Label of the sorting link / entries.
      def sort(name, label: nil)
        label ||= data_class.fields[name].label
        @sorts.natural_push(name.to_sym, nil, label:)
      end

      # DSL method
      # Adds multiple sorts at once, sharing the same kwargs.
      def sorts(*names, **)
        names.each { |name| sort(name, **) }
      end

      # This method must be called before the data is read for the first time. It makes the data fit for display. Only call it once.
      def process_data!(controller)
        fail('Data was already processed!') if @processed_data
        # Filtering
        if filtering_enabled?
          @q = @data.ransack(controller.params[param_name(:q)], auth_object: controller.current_ability, search_key: param_name(:q))
          @q.sorts = @default_sorting if @q.sorts.empty?
          filtered_data = @q.result.accessible_by(controller.current_ability)
        else
          filtered_data = @data
        end
        # Pagination
        if pagination_enabled?
          @page = controller.params[param_name('page')].presence&.to_i || 1
          @pagination_offset = (@page - 1) * @results_per_page
          @total_pages = (filtered_data.count.to_f / @results_per_page).ceil
          if @pagination_offset < 0 || @pagination_offset >= filtered_data.count # out of bounds check
            @page = 1
            @pagination_offset = 0
          end
          @processed_data = filtered_data.offset(@pagination_offset).limit(@results_per_page)
        else
          @processed_data = filtered_data
        end
        # Apply skips to configs
        # Exclude columns that are skipped or the user is not allowed to display
        @columns.select! do |col, _|
          @skipped_columns.exclude?(col[:name]) && controller.current_ability.permitted_attributes(:index, data_class).include?(col[:name])
        end
        # Exclude skipped filters
        @filters.select! { |filter, _| @skipped_filters.exclude?(filter[:name]) }
      end

      setup do
        label(:all) { I18n.t(family_name.humanize) }

        load_data do
          # Prepare raw data. This should not be used directly - processed_data should be used instead
          @data = data_class.accessible_by(controller.current_ability)
        end

        # Default row actions (use override or skip_row_action to prevent)
        row_action(:show)
        row_action(:edit)
        row_action(:destroy)

        before_render do
          process_data!(controller)
        end

        content do
          content :filter if (sorting_in_filter_enabled? && @sorts.any?) || (filtering_enabled? && @filters.any?)
          content :sorting_links if sorting_links_enabled? && @sorts.any?
          content :data
          content :pagination if pagination_enabled? && @total_pages > 1
        end

        content :filter, hidden: true do
          div class: 'list-filter-container' do
            form_html = search_form_for @q, url: url_for, as: param_name(:q) do |f|
              # Sorting in filter
              if sorting_in_filter_enabled? && @sorts.any?
                div class: 'list-sorting-in-filter' do
                  div f.label(:s, I18n.t('compony.components.index.sorting'))
                  div f.select(:s, sorting_in_filter_select_opts, { include_blank: true, selected: params.dig(param_name(:q), :s) })
                end
              end
              # Filters
              if filtering_enabled? && @filters.any?
                div class: 'list-filters' do
                  strong I18n.t('compony.components.index.filters')
                  @filters.each do |filter|
                    div do
                      instance_exec(f, &filter[:payload])
                    end
                  end
                end
              end
              # Submit button
              div class: 'list-filter-button-container' do
                concat f.submit
              end
            end
            concat form_html
          end
        end

        content :sorting_links, hidden: true do
          div do
            strong I18n.t('compony.components.index.sorting')
            @sorts.each do |sort|
              span sort_link(@q, sort[:name], sort[:label])
            end
          end
        end

        content :data, hidden: true do
          table class: 'list-data-table' do
            thead do
              tr do
                @columns.each do |column|
                  th column[:label], class: 'list-data-label'
                end
                if @row_actions.any? { |row_action| @skipped_row_actions.exclude?(row_action[:name]) }
                  th I18n.t('compony.components.index.actions'), class: 'list-actions-label'
                end
              end
            end
            tbody do
              @processed_data.each do |record|
                tr do
                  @columns.each do |column|
                    td class: column[:class] do
                      instance_exec(record, &column[:payload])
                    end
                  end
                  rendered_row_actions = @row_actions.map do |row_action|
                    next if @skipped_row_actions.include?(row_action[:name])
                    next instance_exec(record, &row_action[:payload])
                  end.compact
                  if rendered_row_actions.any?
                    td do
                      rendered_row_actions.each do |row_action_html|
                        concat row_action_html if row_action_html
                      end
                    end
                  end
                end
              end
            end
          end
        end

        content :pagination, hidden: true do
          current_params = request.GET.dup
          div class: 'list-pagination-wrapper' do
            unless @page == 1
              span link_to(I18n.t('compony.components.index.pagination.first'), current_params.merge(param_name('page') =>1)),
                   class: 'list-pagination list-pagination-first'
              span link_to(I18n.t('compony.components.index.pagination.previous'), current_params.merge(param_name('page') =>@page - 1)),
                   class: 'list-pagination list--pagination-previous'
            end
            span @page, class: 'list-pagination list--pagination-current'
            unless @page == @total_pages
              span link_to(I18n.t('compony.components.index.pagination.next'), current_params.merge(param_name('page') =>@page + 1),
                           class: 'list-pagination list--pagination-next')
              span link_to(I18n.t('compony.components.index.pagination.last'), current_params.merge(param_name('page') =>@total_pages),
                           class: 'list-pagination list--pagination-last')
            end
          end
        end
      end

      protected

      # Returns whether filtering is possible and wanted in general (regardless of whether there are any filters defined)
      def filtering_enabled?
        @filtering && defined?(Ransack)
      end

      # Returns whether sorting is possible and wanted in general (regardless of whether there are any sorts defined)
      def sorting_enabled?
        (@sorting_in_filter || @sorting_links) && defined?(Ransack)
      end

      # Returns whether sorting in filter is possible and wanted in general (regardless of whether there are any sorts defined)
      def sorting_in_filter_enabled?
        sorting_enabled? && @sorting_in_filter
      end

      # Returns whether generating sorting links is possible and wanted in general (regardless of whether there are any sorts defined)
      def sorting_links_enabled?
        sorting_enabled? && @sorting_links
      end

      # Returns whether pagination is enabled (regardless of whether there is more than one page)
      def pagination_enabled?
        @pagination
      end

      # Returns the select options for sorting suitable for passing in a `f.select`. Used in sorting-in-filter feature. Useful for custom subclasses of List.
      def sorting_in_filter_select_opts
        @sorts.flat_map do |sort|
          %w[asc desc].map do |order|
            label = "#{sort[:label]} #{order == 'asc' ? '↑' : '↓'}"
            value = "#{sort[:name]} #{order}"
            [label, value]
          end
        end
      end
    end
  end
end
