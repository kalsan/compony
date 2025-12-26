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

        exposed_intents do
          unless data_class.owner_model_attr
            add :new, data_class, name: :new
          end
        end

        content do
          concat render_sub_comp(:list, @data)
        end
      end
    end
  end
end
