RSpec.describe 'Compony routing', type: :request do
  it 'generates a route per standalone component' do
    routes = Rails.application.routes.routes.map { |r| r.path.spec.to_s }
    expect(routes).to include('/users(.:format)')
    expect(routes).to include('/users/show/:id(.:format)')
    expect(routes).to include('/home(.:format)')
  end

  it 'creates named path helpers' do
    expect(Rails.application.routes.url_helpers.index_users_comp_path).to eq('/users')
  rescue NoMethodError
    # Fallback: assert helper name from standalone config
    helper = Components::Users::Index.new.standalone_configs.values.first.path_helper_name
    expect(Rails.application.routes.url_helpers.send(:"#{helper}_path")).to eq('/users')
  end

  it 'routes only the configured verbs' do
    expect { post '/users/show/1' }.to raise_error(ActionController::RoutingError)
  end
end
