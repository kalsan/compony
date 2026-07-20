class Components::Statics::Home < Compony::Component
  setup do
    label(:all) { 'Home' }

    standalone path: 'home' do
      skip_authentication!
      verb :get do
        authorize { true }
      end
    end

    content do
      h1 'Welcome home'
      para 'This is a plain component.'
    end
  end
end
