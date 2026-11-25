class Components::Posts::New < Compony::Components::New
  setup do
    on_created_redirect_path { '/home' }
  end
end
