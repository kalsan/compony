# unreleased

- Add `render_sub_comp` helper
- Major API change: implement `Compony::Intent` as discussed in Issue #14:
    - Rewire many pure helpers to use intents instead, greatly cleaning up their interface
    - Remove pure helpers `rails_action_name`, `path_helper_name`, `comp_cst` and `family_cst`
    - Remove `button_defaults` and associated logic, as it was rarely used
    - Remove `Compony::Components::Button` and replace it by `Compony::Components::Buttons::Link` and `Compony::Components::Buttons::CssButton`
    - Remove `Compony.button`, `compony_button` and `compony_link`
    - Use intents in `sub_comp` and thus also in `resourceful_sub_comp`, allowing tho write something like `sub_comp :list, user.quotes`
- TODO: documentation
- TODO: look for further TODOs

## Steps to take

- Make sure you no longer use the following methods that have been removed:
    - `Compony.rails_action_name`
    - `Compony.path_helper_name`
    - `Compony.button_defaults`
    - `Compony.with_button_defaults`
    - `Compony.button_component_class=` (replace by button styles, see documentation)
    - `Component.comp_cst` (replace by `comp_name`)
    - `Component.family_cst` (replace by `family_name`)
- If using custom buttons, inherit from `Compony::Components::Buttons::Link` and adjust code as needed. Register your button with `Compony.register_button_style` and consider setting `Compony.default_button_style=`.
- Search for each following keywords in your application and replace it as follows:
    - Replace root actions (`action ... do` and `skip_action`)  by exposed intents (see documentation).
    - Replace `render_actions` or `compony_actions` by a custom loop of the kind `Compony.root_comp&.exposed_intents&.map { |i| i.render(controller) }`
    - `Compony.button` was typically used in a component's root actions and should thus already have been replaced in the previous step.
    - Replace `compony_button` by `render_intent`
      - Replace `label_format` by something like: `render_intent(:show, @data, button: { label: { format: :short } })`
    - Replace `compony_link` by `render_intent` and pass `button: { style: :link }` as an argument
- Enhancement: Consider replacing patterns like `sub_comp(Components::Quotes::List, data: user.quotes).render(controller)` by `render_sub_comp(:list, user.quotes)`.

# 0.7.1

- Implement `Compony::VirtualModel` and document it in the Readme file
- Break up documentation into separate files

# 0.7.0

- Rename Component's internal `path` to `id_path` to distinguish it from Rails paths, as well as `path_hash` to `id_path_hash`
- (internal change): switch `WithForm`'s default `submit_path` block to `Compony.path` logic
- Implement new component DSL method `path`, closes #13
    - The method allows components to define the path pointing towards them (the default behavior corresponds to that of `Compony.path` of previous versions)
    - Adjust `Compony.path` to instanciate the target component and use the `path` block rather than come up with the path on its own

## Steps to take

- If using the methods formerly called `path` or `path_hash`, rename them to `id_path` respectively `id_path_hash`.

# 0.6.4

- Replace Feasibility's error message generation in case of dependent errors by a logic that fits fastgettext's modern pluralization

# 0.6.3

- Restrict multi-attachments to upload only when the form's object is a new record

# 0.6.2

- Change download link label of attachments from "Download" to the actual filename
- Support multiple attachments by providing a simple UI for adding and removing attachments

# 0.6.1

- Implement `default_sorting` in `Compony::Components::List`

# 0.6.0

- Implement `Compony::Components::Show`
- Implement `Compony::Components::Index` and `Compony::Components::List`

# 0.5.9

- Fix a bug in generator that was introduced with the previous commit

# 0.5.8

- Apply most recent rubocop recommendations
- Update rubocop
- #10: Implement feasibility framework for links
- Support `BaseComponents`

# 0.5.7

- Fix a minor bug causing unnecessary param `id` to be added to the path after creating or updating when redirecting back to the index component

# 0.5.6

- Allow overriding the label in the view helper `compony_link`

# 0.5.5

- Support `has_one` associations for feasibility

# 0.5.4

- Fix a failure description in Form
- Support `multilang: true` in `ModelMixin`'s and `Form`'s `field` call, as well as in `Form`'s `schema_field`
- Allow customizing parameters for form builder
- Implement `skip_forgery_protection!`

# 0.5.3

- Support `standalone_name` in `Compony.button` and `compony_link`
- Support passing component classes directly to `compony_link`
- Support `button_params` in regular buttons
- Support `value` in submit buttons
- Support `disable!` and `disabled: true` in Form, disabling all inputs

# 0.5.2

- Add `constraints` to `standalone`
- Add `scope` and `scope_args` to `standalone`
- Set default `label_method` to `label` when generating a `simple_form` input for `:association`

# 0.5.1

- Correctly handle `ActiveType::Object` virtual fields in Rails 7.2

# 0.5.0

- Require Ruby 3.3.5 and Rails 7.2.1
- Update Gems Compony depends on (this is to ensure all Compony users have versions Compony is frequently tested against)

## Steps to take

- Update your application to Ruby 3.3.5 and Rails 7.2.1. For instance, if you are running an rbenv setup, these would be typical steps involved:
  - set `rbenv local 3.3.5` and perhaps restart your editor (in particular with VS code)
  - In your Gemfile:
    - switch ruby version to `3.3.5`
    - switch Rails version to `7.2.1`
  - Run bundler:
    - Update bundler itself: `bundle update --bundler`
    - Run `bundle update` or `bundle update --conservative` depending on your preference.
- Check for warnings and react accordingly

# 0.4.1

- Allow the argument `standalone_name` in button and path helper
- Provide family and comp name accessors in the static context as well for convenience
- Make `Compony.path` accept a component class as well
- Make Compony.button accept a component as well. Works in combination with passing a model.
- Fix a bug that caused an override of input option arguments if the `accept` parameter is present

# 0.4.0

- Support Cancancan's `accessible_attributes`
  - Cancancan has fixed https://github.com/CanCanCommunity/cancancan/issues/838
  - Automatically declare all fields as ActiveModel attributes
    - When using this feature together with ActiveType, be sure to add `include ActiveModel::Attributes` at the top of your virtual models.
    - Due to Rails' implementation of `authenticate_by`, `:password` and `:password_confirmation` can not be attributes and thus should no longer be declared as fields in your applications.
      - To handle password fields in forms, `pw_field` and `schema_pw_field` were added
  - Require `cancancan_action` for every Form, respectively `form_cancancan_action` for every WithForm
  - Filter form fields by Cancancan action, effectively providing per-field authorization
  - Attention, this feature is only used when using `field` and `schema_field`, it will not affect custom inputs or schema lines.
  - Require Ruby 3.2.2

## Steps to perform

- If using ActiveType, add `include ActiveModel::Attributes` at the top of your virtual models.
- In your User model, remove `field :password` and `field :password_confirmation`
  - If on login, you get the ArgumentError "One or more password arguments are required", you have forgotten to do this.
- In your User Form:
  - replace `concat field :password` by `concat pw_field :password`
  - replace `concat field :password_confirmation` by `concat pw_field :password_confirmation`
  - replace `schema_field :password` by `schema_pw_field :password`
  - replace `schema_field :password_confirmation` by `schema_pw_field :password_confirmation`
- Make sure your forms work as expected, as cancancan action is now required (see above).
  - Either supply the appropriate action (e.g. `:edit` or `:new`), or pass `nil` to disable per-field authorization for a form.

# 0.3.3

- In `RequestContext`, distinguish between `content` and `content!`, where the first allows for missing content blocks.

# 0.3.2

- Add label content block to edit component
- Introduce `remove_content!` and make its non-bang pendant tolerate missing blocks

# 0.3.1

- In `NaturalOrdering`, tolerate omitting payload only if it's an override
- In `content`, tolerate omitting block if it's an override
- Instanciate a fresh ActionView `output_buffer` when rendering nested content to prevent double render errors
- Reshape `Destroy` and `Form` components to provide more fine-grained content blocks that can be selectively overridden
- Implement `remove_content` which allows removing a previously defined content block (useful for usage in subclasses)

# 0.3.0

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
- Implement nesting of content blocks, as described in README.md -> "Nesting content blocks, calling a content block from another"

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