# Edit with per-field authorization disabled: the authorize blocks are the only protection.
class Components::Posts::EditWithoutFieldAuth < Compony::Components::Edit
  setup do
    standalone path: 'posts/:id/edit_without_field_auth' do
      verb(:get) { authorize { can?(:edit, @data) } }
      verb(:patch) { authorize { can?(:update, @data) } }
    end
    form_cancancan_action nil
    on_updated_redirect_path { '/home' }
  end
end
