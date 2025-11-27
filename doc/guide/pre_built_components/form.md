- [Back to the guide](/README.md#guide--documentation)
- [List of pre-built components](/doc/guide/pre_built_components.md)

# Pre-built components: Form

This component holds a form and should only be instantiated by the `form_comp` call of a component that inherits from [`WithForm`](./with_form.md).

`Compony::Components::Form` is an abstract base class for any components presenting a regular form. This class comes with a lot of tooling for rendering forms and inputs, as well as validating parameters. When the component is rendered, the Gem SimpleForm is used to create the actual form: [https://github.com/heartcombo/simple_form](https://github.com/heartcombo/simple_form).

Parameters are structured like typical Rails forms. For instance, if you have a form for a `User` model and the attribute is `first_name`, the parameter looks like `user[first_name]=Tom`. In this case, we will call `user` the `schema_wrapper_key`. Parameters are validated using Schemacop: [https://github.com/sitrox/schemacop](https://github.com/sitrox/schemacop).

The following DSL calls are provided by the Form component:

- Required: `form_fields` takes a block that renders the inputs of your form. More on that below.
- Optional: `skip_autofocus` will prevent the first input to be auto-focussed when the user visits the form.
- Typically required: `schema_fields` takes the names of fields as a whitelist for strong parameters. Together with model fields, this will completely auto-generate a Schemacop schema suitable for validating this form. If your argument list gets too long, you can use multiple calls to `schema_field` instead to declare your fields one by one on separate lines.
- Optional: `schema_line` takes a single Schemacop line. Use this for custom whitelisting of an argument, e.g. if you have an input that does not have a corresponding model field.
- Optional: `schema` allows you to instead fully define your own custom Schemacop V3 schema manually. Note that this disables all of the above schema calls.
- Optional: `disable!` causes generated inputs to be disabled. Alternatively, `disabled: true` can be passed to the initializer to achieve the same result.

The `form_fields` block acts much like a content block and you will use Dyny there. Two additional methods are made available exclusively inside the block:

- `field` (not to be confused with the model mixin's static method) takes the name of a model field and auto-generates a suitable SimpleForm input as defined in the field's type.
- `f` gives you direct access to the `simple_form` instance. You can use it to write e.g. `f.input(...)`.

Here is a simple example for a form for a sample user:

```ruby
class Components::Users::Form < Compony::Components::Form
  setup do
    form_fields do
      concat field(:first_name)
      concat field(:last_name)
      concat field(:age)
      concat field(:comment)
      concat field(:role)
    end
    schema_fields :first_name, :last_name, :age, :comment, :role
  end
end
```

Note that the inputs and schema are two completely different concepts that are not auto-inferred from each other. You must make sure that they always correspond. If you forget to mention a field in `schema_fields`, posting the form will fail. Luckily, Schemacop's excellent error messaging will explain which parameter is prohibited.

Both calls respect Cancancan's `permitted_attributes` directive. This means that you can safely declare `field` and `schema_field` in a form that is shared among users with different kinds of permissions. If the current user is not allowed to access a field, the input will be omitted automatically. Further, the parameter validation will exclude that field, effectively disallowing that user from submitting that parameter.

## Handling password fields

When using Rails' `has_secure_password` method, which typically generates the attributes accessors `:password` and `password_confirmation`, do not declare these two as fields in your User model.

There are two main reasons for this:

- `password` and `password_confirmation` should never show up in lists and show pages, and as these kinds of components tend to iterate over all fields, it's best to have anything that should not show up there declared as a field in the first place.
- Rails' `authenticate_by` does not work when `password` is declared as a model attribute.

Instead of making these accessors Compony fields, ignore them in the User model and use the following methods in your Form:

```ruby
class Components::Users::Form < Compony::Components::Form
  setup do
    form_fields do
      # ...
      concat pw_field(:password)
      concat pw_field(:password_confirmation)
    end

    # ...
    schema_pw_field :password
    schema_pw_field :password_confirmation
  end
end
```

In contrast to the regular `field` and `schema_field` calls, their `pw_...` pendants do not check for per-field authorization. Instead, they check whether the current user can `:set_password` on the form's object. Therefore, your ability may look something like:

```ruby
class Ability
  # ...
  can :manage, User # This allows full access to all users
  cannot :manage, User, [:user_role] # This prohibits access to user_role, thus removing the input and making the parameter invalid if passed anyway
  cannot :set_password, User # This prohibits setting and changing passwords of any user
```

## Dealing with multilingual fields

When using Gems such as `mobility`, Compony provides support for multilingual fields. For instance, assuming that a model has the attribute `label` translated in English and German, making `label` a virtual attribute reading either `label_en` and `label_de`, depending on the user's language, Compony automatically generates a multilingual field if the following is used:

In the model:

```ruby
class Foo < ApplicationRecord
  # No need to write:
  field :label, :string, virtual: true
  I18n.available_locales.each do |locale|
    field :"label_#{locale}", :string
  end

  # Instead, write this, which is equivalent:
  field :label, :string, multilang: true
end
```

In the same mindset, you can simplify your form as follows to generate one input per language:

```ruby
class Components::Foos::Form < Compony::Components::Form
  setup do
    form_fields do
      # Since `field` only generates an input, you must loop over them and render them as you wish, e.g. with "concat":
      field(:label, multilang: true).each { |inp| concat inp }
    end

    # Don't forget to mark `schema_field` as multilingual as well, which will accept label_en and label_de:
    schema_field :label, multilang: true
  end
end
```