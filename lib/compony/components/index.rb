module Compony
  module Components
    # @api description
    # This component is used for the Rails index paradigm. Nests the `::List` component of the same family.
    class Index < Compony::Component
      include Compony::ComponentMixins::Resourceful

      setup do
        standalone path: family_name do
          verb :get do
            authorize { can? :index, data_class }
          end
        end

        label(:all) { data_class.model_name.human(count: 2) }

        load_data do
          @data = data_class.accessible_by(controller.current_ability)
        end

        action :new do
          if Compony.comp_class_for(:new, data_class)
            Compony.button(:new, data_class.model_name.plural)
          end
        end

        content do
          concat resourceful_sub_comp(component.class.module_parent.const_get(:List)).render(controller)
        end
      end
    end
  end
end
