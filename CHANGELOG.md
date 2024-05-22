# unreleased

- Internals:
  - Change internal parameter handling in edit and update (now use validated params only)
  - Create `NaturalOrdering` which provides an interface for the `action` call behavior
  - Switch actions to `NaturalOrdering`
  - Remove redundant code
- Remove `Component`'s dynamic `comp_class_for` and `comp_class_for!`
- Switch `content` to `NaturalOrdering`, enabling `before:`
  - Remove `add_content`
- Switch `before_render` to `NaturalOrdering`, allowing having multiple `before_render` blocks and overwriting them selectively
  - This change is backwards-compatible as the default behavior of `before_render` is to overwrite `:main`.

## Steps to take

- Search for `comp_class_for` and `comp_class_for!` and replace them by `Compony.comp_class_for` and `Compony.comp_class_for!`
- Search for `add_content` and replace it by `content` along with a name. If you used an index in `add_content`, replace it by `before:` (see documentation)

# 0.2.3

- Support collection of Anchormodels in hidden input

# 0.2.2

- Adjust gemspec
- Generate documentation
- Add VERSION file
- Replace custom anchormodel field implementation by Anchormodel's new implementation of SimpleForm Input

# 0.2.1

- Fix a bug where the app crashed on HEAD verb
- Show more details about failing authorization block
- Implement `submit_path` DSL call for WithForm
- Add French translation
- Implement `skip_autofocus` in Form
- Allow partial override of standalone verb configs. Example:
  ```ruby
    verb :get do
      authorize { true }
    end
    verb :post do
      authorize { true }
      # Parent class implements more logic here, which will no longer be overwritten by calling `verb :post`.
    end
  ```

# 0.2.0

- Cleanup old code
  - Remove `check_config!` that was barely used

# 0.1.1

- Support and force Rails 7.1.2

## Steps to perform

- in `config/application.rb`, replace `config.load_defaults 7.0` by `config.load_defaults 7.1` and add:
  ```ruby
    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))
  ```

# 0.1.0

- Remove (hopefully) obsolete database safeguard in `resolve_association!` as we should no longer be accessing the DB.
- BREAKING: Remove `primary_key_type` and tolerate int and str as primary and foreign key in all params.
  - This fixes a bug introduced in 0.0.10 breaking polymorphic relations.
- Support Rails 7.1
  - No longer rely on `controller.response.body.blank?` but use `controller.response_body.nil?` instead

## Steps to perform

- Remove any calls to `primary_key_type`

# 0.0.9

Do not use.

- Support forms with references to tables with uuid type primary key
- Support for `owned_by` in model:
  - Smart redirect
  - Auto-generate a back / cancel button
- Add `clear_standalone!` to components
- Allow passing an array to `prevent` to prevent multiple actions at once
- Add features `Compony.content_before_root_comp` and `Compony.content_after_root_comp`
- Add new field kind percentage

## KNOWN BUGS

- This version breaks polymorphic relations.

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