module Compony
  module ModelFields
    class Boolean < Base
      def value_for(data, controller: nil, **_)
        return transform_and_join(data.send(@name), controller:) { |el| el.nil? ? nil : I18n.t("compony.boolean.#{el}") }
      end

      def ransack_filter_name
        :"#{@name}_eq"
      end

      def ransack_filter_input(form, **input_opts)
        form.select(
          ransack_filter_name,
          [['', nil], [I18n.t('compony.boolean.true'), true], [I18n.t('compony.boolean.false'), false]],
          {},
          { class: input_opts[:filter_select_class] }
        )
      end
    end
  end
end
