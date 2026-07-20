RSpec.describe 'Authorization', type: :request do
  it 'denies access when the authorize block returns false' do
    expect { get '/secret' }.to raise_error(CanCan::AccessDenied)
  end

  it 'grants access when the authorize block returns true' do
    get '/home'
    expect(response).to have_http_status(:ok)
  end

  it 'hides buttons pointing to unauthorized components' do
    comp = Components::Statics::Secret.new
    controller = ApplicationController.new
    expect(comp.standalone_access_permitted_for?(controller, verb: :get)).to be(false)
  end
end
