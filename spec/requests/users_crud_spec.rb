RSpec.describe 'Users CRUD via pre-built components', type: :request do
  describe 'index' do
    it 'lists users with buttons' do
      alice = User.create!(name: 'Alice')
      get '/users'
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Alice')
      expect(response.body).to include("/users/show/#{alice.id}")
    end

    it 'disables the destroy button for admins (feasibility)' do
      User.create!(name: 'Root', admin: true)
      get '/users'
      expect(response.body).to include('Cannot destroy admins.')
      expect(response.body).to include('disabled')
    end
  end

  describe 'show' do
    it 'renders the fields of the user' do
      user = User.create!(name: 'Alice', age: 30, comment: 'Hi there')
      get "/users/show/#{user.id}"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('<h3>Alice</h3>')
      expect(response.body).to include('Hi there')
      expect(response.body).to include('30')
    end

    it 'raises RecordNotFound for a missing id' do
      expect { get '/users/show/999999' }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'new/create' do
    it 'renders the form' do
      get '/users/new'
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('form')
      expect(response.body).to include('user[name]')
      expect(response.body).to include('user[age]')
    end

    it 'creates a user and redirects' do
      expect do
        post '/users/new', params: { user: { name: 'Bob', age: '25', comment: 'New guy', email: 'bob@example.com', admin: '0', born_on: '2000-01-01' } }
      end.to change(User, :count).by(1)
      user = User.order(:id).last
      expect(user.name).to eq('Bob')
      expect(user.age).to eq(25)
      expect(user.born_on).to eq(Date.new(2000, 1, 1))
      expect(response).to have_http_status(:found)
    end

    it 're-renders the form on validation errors' do
      expect do
        post '/users/new', params: { user: { name: '' } }
      end.not_to change(User, :count)
      expect(response.body).to include('form')
    end
  end

  describe 'edit/update' do
    let(:user) { User.create!(name: 'Alice', age: 30) }

    it 'renders the form with existing values' do
      get "/users/#{user.id}/edit"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Alice')
    end

    it 'updates the user and redirects' do
      patch "/users/#{user.id}/edit", params: { user: { name: 'Alicia' } }
      expect(user.reload.name).to eq('Alicia')
      expect(response).to have_http_status(:found)
    end

    it 'does not update on validation errors' do
      patch "/users/#{user.id}/edit", params: { user: { name: '' } }
      expect(user.reload.name).to eq('Alice')
    end
  end

  describe 'destroy' do
    it 'asks for confirmation on GET' do
      user = User.create!(name: 'Alice')
      get "/users/#{user.id}/destroy"
      expect(response).to have_http_status(:ok)
      expect(User.exists?(user.id)).to be(true)
    end

    it 'destroys on DELETE and redirects' do
      user = User.create!(name: 'Alice')
      expect do
        delete "/users/#{user.id}/destroy"
      end.to change(User, :count).by(-1)
      expect(response).to have_http_status(:see_other) # 303 forces a GET, required for Turbo
    end
  end
end
