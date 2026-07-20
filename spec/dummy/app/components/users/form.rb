class Components::Users::Form < Compony::Components::Form
  setup do
    form_fields do
      concat field(:name)
      concat field(:age)
      concat field(:comment)
      concat field(:email)
      concat field(:admin)
      concat field(:born_on)
    end

    schema_fields :name, :age, :comment, :email, :admin, :born_on
  end
end
