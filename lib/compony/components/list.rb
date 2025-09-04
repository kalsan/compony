module Compony
  module Components
    # @api description
    # This component is used for the Rails list paradigm. It is meant to be nested inside the same family's `::Index` or an owner's `::Show` component.
    class List < Compony::Component
      include Compony::ComponentMixins::Resourceful

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
        @filter_label_class = 'list-filter-label'
        @filter_input_class = 'list-filter-input'
        @filter_select_class = 'list-filter-select'
        @filter_item_wrapper_class = nil
        super(*, **)
      end

      def skip_pagination!
        @pagination = false
      end

      def results_per_page(new_results_per_page)
        @results_per_page = new_results_per_page
      end

      def skip_filtering!
        @filtering = false
      end

      def skip_sorting!
        @sorting_in_filter = false
        @sorting_links = false
      end

      def skip_sorting_in_filter!
        @sorting_in_filter = false
      end

      def skip_sorting_links!
        @sorting_links = false
      end

      def filter_label_class(class_str)
        @filter_label_class = class_str
      end

      def filter_input_class(class_str)
        @filter_input_class = class_str
      end

      def filter_select_class(class_str)
        @filter_select_class = class_str
      end

      def filter_item_wrapper_class(class_str)
        @filter_item_wrapper_class = class_str
      end

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

      def columns(*col_names, **)
        col_names.each { |col_name| column(col_name, **) }
      end

      def skip_column(name)
        @skipped_columns << name.to_sym
      end

      def row_action(name, button_opts: {}, **, &block)
        name = name.to_sym
        unless block_given?
          block = proc do |record|
            next if Compony.comp_class_for(name, record).nil?
            compony_button(name, record, **button_opts)
          end
        end
        @row_actions.natural_push(name, block, **)
      end

      def skip_row_action(name)
        @skipped_row_actions << name.to_sym
      end

      def filter(name, label: nil, **, &block)
        name = name.to_sym
        unless block_given?
          field = data_class.fields[name]
          block = proc do |f|
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

      def filters(*filter_names, **)
        filter_names.each { |filter_name| filter(filter_name, **) }
      end

      def sort(name, label: nil)
        label ||= data_class.fields[name].label
        @sorts.natural_push(name.to_sym, nil, label:)
      end

      def sorts(*names, **)
        names.each { |name| sort(name, **) }
      end

      def process_data!(controller)
        fail('Data was already processed!') if @processed_data
        # Filtering
        if filtering_enabled?
          @q = @data.ransack(controller.params[param_name(:q)], auth_object: controller.current_ability, search_key: param_name(:q))
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

      def filtering_enabled?
        @filtering && defined?(Ransack)
      end

      def sorting_enabled?
        (@sorting_in_filter || @sorting_links) && defined?(Ransack)
      end

      def sorting_in_filter_enabled?
        sorting_enabled? && @sorting_in_filter
      end

      def sorting_links_enabled?
        sorting_enabled? && @sorting_links
      end

      def pagination_enabled?
        @pagination
      end

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
