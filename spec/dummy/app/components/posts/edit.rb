class Components::Posts::Edit < Compony::Components::Edit
  setup do
    on_updated_redirect_path { '/home' }
  end
end
