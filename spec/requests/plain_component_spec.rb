RSpec.describe 'Plain standalone component', type: :request do
  it 'renders content within the application layout' do
    get '/home'
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('data-layout="application"')
    expect(response.body).to include('<h1>Welcome home</h1>')
    expect(response.body).to include('<p>This is a plain component.</p>')
  end
end
