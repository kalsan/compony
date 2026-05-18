[Back to the guide](/README.md#guide--documentation)

# DSL reference

Flat lookup of every Compony DSL method, its calling context, signature, and a one-line
description. This page is generated from `# DSL method` markers in the source — when in
doubt the Ruby source under `lib/compony/` is authoritative. "Context" says where the call
is legal.

Contexts:

- **class** — directly in the component class body.
- **setup** — inside `setup do ... end`.
- **standalone** — inside `standalone do ... end`.
- **verb** — inside `verb :x do ... end`.
- **form_fields** — inside a Form component's `form_fields do ... end`.
- **content** — inside a `content do ... end` block (a RequestContext).
- **model** — in an `ActiveRecord`/model class that `include`s the model mixin.

## Component definition

| Method | Context | Signature | Description |
| --- | --- | --- | --- |
| `setup` | class | `setup { block }` | Main config block. Runs at end of init; parent runs before child. |
| `label` | setup | `label(:short/:long/:all) { \|model\| ... }` | Component title + link/button text. Resourceful comps take 1 block arg. |
| `color` | setup | `color { '#AA0000' }` | Component color (not used by Compony itself). |
| `icon` | setup | `icon { %i[fa-solid circle] }` | Component icon (not used by Compony itself). |
| `content` | setup | `content(name = :main, before: nil, hidden: false) { block }` | Define/replace a named view block (Dyny). `hidden: true` = don't auto-render. Non-obvious use: hidden `:main` + `:wrapper` chrome → [patterns §1](/doc/guide/patterns.md#1-the-app-base-component-layer). |
| `content` | content | `content(:name)` | Render another content block of the *same* component (nesting). [patterns §1](/doc/guide/patterns.md#1-the-app-base-component-layer). |
| `remove_content` | setup | `remove_content(:name)` | Remove an inherited content block (returns false if absent). |
| `remove_content!` | setup | `remove_content!(:name)` | Same, raises if the block was not found. |
| `before_render` | setup | `before_render(name = :main, before: nil) { block }` | Pre-content hook. If it sets a response body (e.g. redirect), content is skipped. Non-obvious uses: verb-independent guard → [patterns §8](/doc/guide/patterns.md#8-lifecycle-hooks-for-derived-data); wizard step nav → [patterns §16](/doc/guide/patterns.md#16-multi-step-wizard-across-components). |
| `exposed_intents` | setup | `exposed_intents { add ...; remove ... }` | Declare intents the layout/parent renders. See `add`/`remove`, and the toolbar pattern → [patterns §9](/doc/guide/patterns.md#9-exposed-intents-as-the-action-toolbar). |
| `path` | setup | `path { \|model, *args, standalone_name:, **kw\| ... }` | Override path generation for this component (advanced). Runs outside the request context — build URLs via `Rails.application.routes.url_helpers`. Non-obvious use: mint a signed token into the URL → [patterns §18](/doc/guide/patterns.md#18-signed-token-capability-links-auth-less-onboarding--magic-links); see also [standalone.md](/doc/guide/standalone.md#customizing-path-generation). |

`exposed_intents` DSL (inside its block):

| Method | Signature | Description |
| --- | --- | --- |
| `add` | `add(comp, model_or_family, before: nil, **intent_opts)` | Add/replace an exposed intent (keyed by intent name). |
| `remove` | `remove(:intent_name)` | Remove a previously added exposed intent. |

## Standalone (routing)

| Method | Context | Signature | Description |
| --- | --- | --- | --- |
| `standalone` | setup | `standalone(name = nil, path:, constraints: nil, scope: nil, scope_args: {}) { ... }` | Generate a Rails route. Non-obvious use: a *named* extra `standalone` for an ajax companion endpoint of the same screen → [patterns §17](/doc/guide/patterns.md#17-inline-patch-without-a-form-reorder--quick-toggle). |
| `verb` | standalone | `verb(:get/:post/:patch/:put/:delete/...) { ... }` | Config one HTTP verb. Up to once per verb per standalone. |
| `skip_authentication!` | standalone | `skip_authentication!` | Disable app authentication for this standalone (still need `authorize`). Non-obvious use: token-gated auth-less links → [patterns §18](/doc/guide/patterns.md#18-signed-token-capability-links-auth-less-onboarding--magic-links). |
| `skip_forgery_protection!` | standalone | `skip_forgery_protection!` | Disable CSRF for this standalone's action. Non-obvious use: inbound webhooks → [patterns §13](/doc/guide/patterns.md#13-public-endpoints--webhooks). |
| `layout` | standalone | `layout('layouts/backend')` | Rails layout for this standalone. Defaults to `layouts/application`. Centralize in the base layer → [patterns §1](/doc/guide/patterns.md#1-the-app-base-component-layer). |
| `authorize` | verb | `authorize { can?(:read, @data) }` | **Mandatory.** Truthy = access; falsy → `CanCan::AccessDenied`. Non-obvious use: validate a signed token → [patterns §18](/doc/guide/patterns.md#18-signed-token-capability-links-auth-less-onboarding--magic-links). |
| `respond` | verb | `respond(format = nil) { ... }` | Override the controller response (e.g. send_data, render json, redirect). Overriding `nil` format **skips `authorize`** — re-check yourself. Non-obvious uses: CSV/PDF export → [patterns §10](/doc/guide/patterns.md#10-csv--pdf-via-respond-format); ajax-only PATCH → [patterns §17](/doc/guide/patterns.md#17-inline-patch-without-a-form-reorder--quick-toggle). |

## Resourceful lifecycle hooks

Available in **setup** (global, all verbs) on resourceful components; the same names also
work inside a **verb** block to override for one path+verb.

| Method | Signature | Description |
| --- | --- | --- |
| `data_class` | `data_class(NewClass = nil)` | Set/get the model class. Defaults to family name singularized+constantized. Non-obvious use: point at a `VirtualModel` → [patterns §12](/doc/guide/patterns.md#12-virtual-model-for-non-persistent--upload-forms). |
| `load_data` | `load_data { @data = ... }` | Override record loading. Default: `data_class.find(params[:id])`. Runs before `authorize`. Non-obvious uses: Index scope → [patterns §3](/doc/guide/patterns.md#3-index--load_data-scope--nested-list); load+dup for clone → [patterns §11](/doc/guide/patterns.md#11-non-crud-job-dispatch-toggles-clone). |
| `after_load_data` | `after_load_data { ... }` | Runs after `load_data`, before `authorize`. Refine an AR relation here. |
| `assign_attributes` | `assign_attributes { ... }` | Assign validated params onto `@data`. Pre-built forms supply a default. |
| `after_assign_attributes` | `after_assign_attributes { ... }` | After `assign_attributes`, before `store_data`. Prefill/derive fields here → [patterns §8](/doc/guide/patterns.md#8-lifecycle-hooks-for-derived-data); seed from a token → [patterns §18](/doc/guide/patterns.md#18-signed-token-capability-links-auth-less-onboarding--magic-links). |
| `store_data` | `store_data { @data.save }` | Persist `@data`. Override for virtual models / uploads → [patterns §12](/doc/guide/patterns.md#12-virtual-model-for-non-persistent--upload-forms), or to enqueue work / multi-record txn → [patterns §11](/doc/guide/patterns.md#11-non-crud-job-dispatch-toggles-clone). |

## Form component DSL

`class Components::X::Form < Compony::Components::Form`

| Method | Context | Signature | Description |
| --- | --- | --- | --- |
| `form_fields` | setup | `form_fields { ... }` | **Mandatory.** Block holding the form inputs (Dyny + `field`/`f`). |
| `field` | form_fields | `field(:name, multilang: false, **simple_form_opts)` | Render a simple_form input inferred from the model field. `as:`/`hidden:` supported. |
| `pw_field` | form_fields | `pw_field(:password, **opts)` | Password input; checks `:set_password` ability. |
| `f` | form_fields | `f` | The underlying `simple_form` builder (for `f.rich_text_area` etc.). |
| `collect` | form_fields | `collect(...)` | Wrap a collection in Rails-compatible format (Anchormodel helper). |
| `schema_field` | setup | `schema_field(:name, multilang: false)` | Whitelist one field in the Schemacop param schema. For associations use the **association name**, not `_id`. |
| `schema_fields` | setup | `schema_fields(:a, :b, ...)` | Mass `schema_field`. |
| `schema_pw_field` | setup | `schema_pw_field(:password)` | Whitelist a password param (checks `:set_password`). |
| `schema_line` | setup | `schema_line { str? :foo }` | Add a raw Schemacop3 line (nested attrs, custom shapes) → [patterns §5](/doc/guide/patterns.md#5-custom-form--schemacop-kept-in-sync). |
| `schema` | setup | `schema(:wrapper_key) { ... }` | Replace the whole schema + wrapper key (fully manual). |
| `form_params` | setup | `form_params(**opts)` | Extra kwargs passed to `simple_form_for`. |
| `disable!` | setup | `disable!` | Render all inputs disabled. |
| `skip_autofocus` | setup | `skip_autofocus` | Don't autofocus the first field. |

WithForm / New / Edit wiring (in the New/Edit component's `setup`):

| Method | Signature | Description |
| --- | --- | --- |
| `submit_verb` | `submit_verb(:patch)` | HTTP verb the form submits with (`:post` for New, `:patch` for Edit). |
| `form_comp_class` | `form_comp_class(Components::X::MyForm)` | Use a custom Form component instead of `Components::<Family>::Form`. Non-obvious uses: non-default form → [patterns §5](/doc/guide/patterns.md#5-custom-form--schemacop-kept-in-sync); token-gated signup → [patterns §18](/doc/guide/patterns.md#18-signed-token-capability-links-auth-less-onboarding--magic-links). |
| `form_cancancan_action` | `form_cancancan_action(:edit)` | CanCanCan action used for per-field `permitted_attributes`. Pass `nil` to disable per-field auth (e.g. token-gated forms → [patterns §18](/doc/guide/patterns.md#18-signed-token-capability-links-auth-less-onboarding--magic-links)). |
| `submit_path` | `submit_path { Compony.path(...) }` | Override where the form POSTs/PATCHes to. Non-obvious use: carry a token through submit → [patterns §18](/doc/guide/patterns.md#18-signed-token-capability-links-auth-less-onboarding--magic-links). |
| `on_created` / `on_updated` | `on_created { ... }` | Post-save, pre-respond hook (success). |
| `on_created_respond` / `on_updated_respond` | `... { ... }` | Override the success response (default: flash + redirect). |
| `on_created_redirect_path` / `on_updated_redirect_path` | `... { path }` | Override the success redirect target. Non-obvious use: chain wizard steps → [patterns §16](/doc/guide/patterns.md#16-multi-step-wizard-across-components). |
| `on_create_failed_respond` / `on_update_failed` | `... { ... }` | Override the validation-failure response. |
| `on_destroyed` / `on_destroyed_respond` / `on_destroyed_redirect_path` | `... { ... }` | Destroy component equivalents. |

## List / Index component DSL

`Compony::Components::List` (nest in Index or owner Show); `Compony::Components::Index`.

| Method | Context | Signature | Description |
| --- | --- | --- | --- |
| `column` | setup | `column(:name, label: nil, class: nil, link_opts: {}) { \|record\| ... }` | Add/define a column; block renders the cell. |
| `columns` | setup | `columns(:a, :b, as_title: false)` | Add several field-based columns. `as_title: true` = card title on mobile. |
| `filter` | setup | `filter(:name, label: nil) { \|f\| ... }` | Add/define a filter; block customizes the input. |
| `filters` | setup | `filters(:a, :b)` | Add several filters. |
| `sort` | setup | `sort(:name, label: nil)` | Add a sort option. |
| `sorts` | setup | `sorts(:a, :b)` | Add several sort options. |
| `default_sorting` | setup | `default_sorting('id desc')` | Default Ransack sort string. |
| `row_intents` | setup | `row_intents(**opts) { add/remove }` | Per-row action buttons (intent DSL) → [patterns §4](/doc/guide/patterns.md#4-list-customization). |
| `pagination` | setup | `pagination(false)` | Enable/disable pagination (caution: loads all rows). |
| `results_per_page` | setup | `results_per_page(20)` | Rows per page when paginating. |
| `filtering` | setup | `filtering(false)` | Enable/disable filtering entirely. |
| `sorting` | setup | `sorting(false)` | Enable/disable both sorting links and in-filter sorting. |
| `sorting_in_filter` / `sorting_links` | setup | `sorting_links(false)` | Toggle one sorting UI independently. |
| `filter_label_class` / `filter_input_class` / `filter_select_class` | setup | `filter_input_class('...')` | CSS classes for filter form elements. |
| `skip_column` | setup | `skip_column(:name)` | Remove an inherited column (Show/List). |

Many of these also accept `skip_*` kwargs on the constructor when the List is nested via
`render_sub_comp` (e.g. `render_sub_comp(:list, coll, skip_pagination: true)`).

## Model mixin (in your `ApplicationRecord` models)

| Method | Context | Signature | Description |
| --- | --- | --- | --- |
| `field` | model (class) | `field(:name, :type, multilang: false, **attrs)` | Declare a UI-relevant attribute + its type/formatting. |
| `prevent` | model (class) | `prevent(:destroy, 'msg') { condition }` | Feasibility: block returns truthy → action prevented (buttons disabled). |
| `owned_by` | model (class) | `owned_by(:invoice)` | Mark this model as owned by another; adjusts redirects/top actions. |
| `skip_autodetect_feasibilities` | model (class) | `skip_autodetect_feasibilities` | Don't auto-derive `:destroy` preventions from `dependent:` associations. |
| `feasible?` | model (instance) | `record.feasible?(:destroy)` | True if no prevention blocks the action. |
| `feasibility_messages` | model (instance) | `record.feasibility_messages(:destroy)` | Array of reasons (like `errors`). |
| `full_feasibility_messages` | model (instance) | `record.full_feasibility_messages(:destroy)` | Joined human string (like `full_messages`). |

`label` is not a DSL method but **every Compony model must implement `def label`** (or have
a `label` column) — used for titles and link text.

## Intent / navigation helpers

Used from `content` blocks or controllers — see [intents.md](/doc/guide/intents.md).

| Method | Context | Signature | Description |
| --- | --- | --- | --- |
| `Compony.intent` | anywhere | `Compony.intent(:show, model, **opts)` | Build an `Intent`. |
| `Compony.path` | anywhere | `Compony.path(:index, :users, **opts)` | Rails path string (redirects). |
| `render_intent` | content | `render_intent(:edit, model, style:, label:, button:)` | Render a link/button to a component. Wrap in `concat`. |
| `render_sub_comp` | content | `render_sub_comp(:list, @data.quotes, **opts)` | Instantiate + nest another component. Wrap in `concat`. |
| `Compony.comp_class_for` | anywhere | `Compony.comp_class_for(:show, family)` | Comp class or `nil`. |

[Guide index](/README.md#guide--documentation)
