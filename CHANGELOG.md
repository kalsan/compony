# unreleased

- Support forms with references to tables with uuid type primary key
- Support for `owned_by` in model:
  - Smart redirect
  - Auto-generate a back / cancel button
- Add `clear_standalone!` to components
- Allow passing an array to `prevent` to prevent multiple actions at once
- Add features `Compony.content_before_root_comp` and `Compony.content_after_root_comp`
- Add new field kind percentage

# 0.0.8

- Support selecting anchormodel inputs via radio buttons
- Fix `value_for` for associations to elements that have no show component
- Fix spacing problem with invisible action buttons
- Pass the controller as argument to action buttons
- Support option `:label` in `value_for` of date and datetime, support superfluous options in association
- Support argument list in form generator
- Create new model field type :color

# 0.0.7

- Fix `standalone_access_permitted_for?` check for buttons pointing to non-get verbs

# 0.0.6

- Fix a bug that breaks hidden fields of type reference
- Add dynamic method "field" to model mixin
- Tolerate and skip actions that do not define buttons, allows for dynamic action skipping
- Fix `value_for` for boolean fields when they are nil
- BREAKING: Rename `on_created` to `on_created_respond`, `on_updated` to `on_updated_respond`, and `on_destroyed` to `on_destroyed_respond`
  - New hooks `on_created`, `on_updated`, and `on_destroyed` are called before their `_respond` counterpart
- Fix a bug in Attachment Field
- Support overriding simpleform name by providing `name:` as an argument to field.simpleform_input
- In ModelField Anchormodel, tolerate "value" as input_html key and infer correct constant, allow form.object to be missing

# 0.0.5

- Fix row bug for Email field type
- Auto-focus first non-hidden element in forms
- Add field type :url
- Automatically set the correct class when generating known components
- Add generator `components` that is able to mass-produce the most used components
- Make fields point to the correct `model_class` in case of STI
- Support hidden Anchormodel fields

## KNOWN BUGS

- Breaks hidden fields of type reference

# 0.0.4

- Unscope the namespace of resourceful components
- Add field type :email

## Steps to take

- When inheriting from components, replace `Components::Resourceful::...` by `Components::...`

# 0.0.3

- Tolerate nil anchormodels
- Fix a nil pointer bug in namespace management

# 0.0.2

- Add new model field `Attachment`
- Slightly extend documentation
- Update `Gemfile.lock`

# 0.0.1

First version