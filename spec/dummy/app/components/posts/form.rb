class Components::Posts::Form < Compony::Components::Form
  setup do
    form_fields do
      concat field(:title)
      concat field(:owner)
      concat field(:tags)
      concat field(:locked)
    end

    schema_fields :title, :owner, :tags, :locked
  end
end
