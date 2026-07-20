class Components::Statics::Secret < Compony::Component
  setup do
    label(:all) { 'Secret' }

    standalone path: 'secret' do
      verb :get do
        authorize { false }
      end
    end

    content do
      h1 'You should never see this'
    end
  end
end
