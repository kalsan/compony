# Edit that intentionally counts views on GET, which must survive the rollback of the GET.
class Components::Posts::CountViewPersistently < Compony::Components::Edit
  setup do
    standalone path: 'posts/:id/count_view_persistently' do
      verb(:get) { authorize { can?(:edit, @data) } }
      verb(:patch) { authorize { can?(:update, @data) } }
    end
    before_render do
      post_id = @data.id
      outside_rollback { Post.where(id: post_id).update_all('views = views + 1') }
    end
    on_updated_redirect_path { '/home' }
  end
end
