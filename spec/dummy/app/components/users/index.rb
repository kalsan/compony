class Components::Users::Index < Compony::Component
  include Compony::ComponentMixins::Resourceful

  setup do
    label(:all) { 'Users' }
    standalone path: 'users' do
      verb :get do
        authorize { true }
      end
    end

    load_data { @data = User.order(:id) }

    content do
      h4 'Users:'
      concat render_intent(:new, :users)
      div class: 'users' do
        @data.each do |user|
          div class: 'user' do
            span user.name
            concat render_intent(:show, user, button: { label: { format: :short } })
            concat render_intent(:edit, user, button: { label: { format: :short } })
            concat render_intent(:destroy, user, button: { label: { format: :short } })
          end
        end
      end
    end
  end
end
