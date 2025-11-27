[Back to the guide](/README.md#guide)

# Model fields

Compony fields are your models' attributes that you wish to expose in your application's UI. They are a central place to store important information about those attributes, accessible from everywhere and without the need for a database connection.

Every Compony field must define at least a name and type. Compony types and ActiveRecord types are similar but not equivalent. While ActiveRecord uses types for storing data in the DB, Compony fields use them for presenting it. For instance, the Compony "string" type covers any kind of string, including ActiveRecord's "string", "text" etc. Similarly, Compony has no "numeric" type - use "integer" or "decimal" instead, depending on whether or not you want to show decimals or not. There are additional field types like "color", "url" etc. You can find a complete list of all Compony field types in the module `Compony::ModelFields`.

Compony fields support Postgres arrays (non-nested).

A particularly interesting model field is `Association` which handles `belongs_to`, `has_many` and `has_one` associations, automatically resolving the association's nature and providing links to the appropriate component.

Every Compony field can further take an arbitrary amount of additional named arguments. Those can be retrieved by calling `YourRailsModel.fields[:field_name].extra_attrs`.


Here is an example call to fields for a User model:

```ruby
# app/models/user.rb
class User < ApplicationRecord
  field :first_name, :string
  field :last_name, :string
  field :user_role, :anchormodel
  field :website, :url
  field :created_at, :datetime
  field :updated_at, :datetime
end
```

All fields declared this way are automatically exported as Rails Model attributes. Note that this also means that you should never declare `password` and `password_confirmation` as a Compony field, as you will get the ArgumentError "One or more password arguments are required" otherwise. Read more about handling password fields in the section about `Compony::Components::Form`.

Compony fields provide the following features:

- a label that lets you generate a name for the column: `User.fields[:first_name].label`
- `value_for`: given a model instance, formats the data (e.g. a field of type "url" will produce a link).
- Features for forms:
  - `simpleform_input` auto-generates in input for a simple form (from the `simple_form` gem).
  - `simpleform_input_hidden` auto-generates a hidden input.
  - `schema_line` auto-generates a DSL call for Schemacop v3 (from the `schemacop` gem), which is useful for parameter validation.

You can then use these fields in other components, for instance a list as described in the example at the top of this guide:

```ruby
User.fields.values.each do |field|
  span do
    concat "#{field.label}: #{field.value_for(user)} " # Display the field's label and apply it to value
  end
end
```

## Implementing your own fields

You can implement your own model fields. Make sure they are all within the same namespace and inherit at least from `Compony::ModelFields::Base`. To enable them, write an initializer that overwrites the array `Compony.model_field_namespaces`. Namespaces listed in the array are prioritized from first to last. If a field (e.g. `String`) exists in multiple declared namespaces, the first will be used. This allows you to overwrite Compony fields.

Example:

```ruby
# config/initializers/compony.rb
Compony.model_field_namespaces = ['MyCustomModelFields', 'Compony::ModelFields']
```

You can then implement `MyCustomModelFields::Animal`, `MyCustomModelFields::String` etc. You can then use `field :fav_animal, :animal` in your model.

[Guide index](/README.md#guide)