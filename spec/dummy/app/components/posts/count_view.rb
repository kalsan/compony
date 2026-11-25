# Edit whose hook writes to the database while assigning, as some apps do to run an action.
class Components::Posts::CountView < Compony::Components::Edit
  setup do
    standalone path: 'posts/:id/count_view' do
      verb(:get) { authorize { can?(:edit, @data) } }
      verb(:patch) { authorize { can?(:update, @data) } }
    end
    after_assign_attributes { @data.increment!(:views) }
    on_updated_redirect_path { '/home' }
  end
end
