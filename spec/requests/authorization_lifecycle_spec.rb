# Authorization around assign_attributes: a GET that assigns never persists, a persisted record is authorized as stored and as
# modified, and a user who may open but not submit an edit page gets a read-only form.
RSpec.describe 'Authorization lifecycle', type: :request do
  let!(:victim) { User.create!(name: 'Victim') }
  let!(:attacker) { User.create!(name: 'Attacker') }
  let!(:tag) { Tag.create!(name: 'Tagged') }
  let!(:victims_post) { Post.create!(title: 'Victim title', owner: victim) }
  let!(:attackers_post) { Post.create!(title: 'Attacker title', owner: attacker) }

  def use_ability(&rules)
    ability = Class.new { include CanCan::Ability }.new
    ability.instance_exec(&rules)
    allow(Ability).to receive(:new).and_return(ability)
  end

  # Rules of an app where users manage their own posts only.
  def own_posts_only
    attacker_id = attacker.id
    use_ability { can %i[read edit update], Post, owner_id: attacker_id }
  end

  describe 'GET with assign_attributes' do
    before { use_ability { can :manage, :all } }

    it 'still prefills the form from params' do
      get "/posts/#{victims_post.id}/edit", params: { post: { title: 'Prefilled' } }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Prefilled')
      expect(victims_post.reload.title).to eq('Victim title')
    end

    it 'does not persist has_many ids assigned from params' do
      get "/posts/#{victims_post.id}/edit", params: { post: { tag_ids: [tag.id] } }
      expect(response).to have_http_status(:ok)
      expect(victims_post.reload.tag_ids).to be_empty
    end

    it 'does not persist writes made by hooks' do
      get "/posts/#{victims_post.id}/count_view"
      expect(response).to have_http_status(:ok)
      expect(victims_post.reload.views).to eq(0)
    end

    it 'does not persist writes on HEAD either' do
      head "/posts/#{victims_post.id}/count_view"
      expect(victims_post.reload.views).to eq(0)
    end

    it 'persists writes wrapped in outside_rollback' do
      get "/posts/#{victims_post.id}/count_view_persistently"
      expect(response).to have_http_status(:ok)
      expect(victims_post.reload.views).to eq(1)
    end

    it 'skips writes wrapped in outside_rollback when the request is refused' do
      use_ability { can :read, Post }
      expect { get "/posts/#{victims_post.id}/count_view_persistently" }.to raise_error(CanCan::AccessDenied)
      expect(victims_post.reload.views).to eq(0)
    end

    it 'keeps persisting writes of hooks on PATCH' do
      patch "/posts/#{victims_post.id}/count_view", params: { post: { title: 'Changed' } }
      expect(victims_post.reload).to have_attributes(views: 1, title: 'Changed')
    end
  end

  describe 'persisted record authorized as stored' do
    before { own_posts_only }

    it 'refuses taking over a foreign record by changing the attribute authorization depends on' do
      expect do
        patch "/posts/#{victims_post.id}/edit_without_field_auth", params: { post: { title: 'Taken', owner_id: attacker.id } }
      end.to raise_error(CanCan::AccessDenied)
      expect(victims_post.reload).to have_attributes(title: 'Victim title', owner_id: victim.id)
    end

    it 'refuses showing a foreign record prefilled to pass authorization' do
      expect do
        get "/posts/#{victims_post.id}/edit_without_field_auth", params: { post: { owner_id: attacker.id } }
      end.to raise_error(CanCan::AccessDenied)
    end

    it 'refuses before assigning, so has_many ids are not written for unauthorized users' do
      use_ability { can :edit, Post } # may open the edit page (and passes the field filter), but may not update
      expect do
        patch "/posts/#{victims_post.id}/edit_without_field_auth", params: { post: { tag_ids: [tag.id] } }
      end.to raise_error(CanCan::AccessDenied)
      expect(victims_post.reload.tag_ids).to be_empty
    end
  end

  describe 'persisted record authorized as modified' do
    before { own_posts_only }

    it 'still refuses handing an own record to someone the user may not act for' do
      expect do
        patch "/posts/#{attackers_post.id}/edit_without_field_auth", params: { post: { owner_id: victim.id } }
      end.to raise_error(CanCan::AccessDenied)
      expect(attackers_post.reload.owner_id).to eq(attacker.id)
    end

    it 'still updates an own record' do
      patch "/posts/#{attackers_post.id}/edit", params: { post: { title: 'Renamed' } }
      expect(attackers_post.reload.title).to eq('Renamed')
    end
  end

  describe 'new record' do
    before do
      attacker_id = attacker.id
      use_ability do
        can :new, Post
        can :create, Post, owner_id: attacker_id
      end
    end

    it 'is authorized after assignment, so conditions on assigned attributes work' do
      expect do
        post '/posts/new', params: { post: { title: 'Mine', owner_id: attacker.id } }
      end.to change(Post, :count).by(1)
    end

    it 'refuses creating a record the user may not own' do
      expect do
        post '/posts/new', params: { post: { title: 'Theirs', owner_id: victim.id } }
      end.to raise_error(CanCan::AccessDenied)
    end
  end

  describe 'read-only edit page' do
    before { use_ability { can %i[read edit], Post } }

    it 'renders the form disabled and without buttons for a user who may edit but not update' do
      get "/posts/#{victims_post.id}/edit"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Victim title')
      expect(response.body).to match(/<input[^>]*disabled[^>]*name="post\[title\]"|<input[^>]*name="post\[title\]"[^>]*disabled/)
      expect(response.body).not_to include('compony-form-buttons')
    end

    it 'refuses the submit' do
      expect do
        patch "/posts/#{victims_post.id}/edit", params: { post: { title: 'Changed' } }
      end.to raise_error(CanCan::AccessDenied)
    end

    it 'renders the form enabled with buttons for a user who may update' do
      use_ability { can :manage, Post }
      get "/posts/#{victims_post.id}/edit"
      expect(response.body).to include('compony-form-buttons')
      expect(response.body).not_to match(/<input[^>]*disabled[^>]*name="post\[title\]"/)
    end
  end
end
