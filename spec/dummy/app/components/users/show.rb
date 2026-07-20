class Components::Users::Show < Compony::Component
  include Compony::ComponentMixins::Resourceful

  setup do
    label(:short) { |_u| 'Show' }
    label(:long) { |u| "Show user #{u.label}" }

    standalone path: 'users/show/:id' do
      verb :get do
        authorize { true }
      end
    end

    content do
      h3 @data.label
      table do
        tr do
          @data.fields.each_value { |field| th field.label }
        end
        tr do
          @data.fields.each_value { |field| td field.value_for(@data, controller:) }
        end
      end
    end
  end
end
