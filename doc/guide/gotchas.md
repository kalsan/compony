[Back to the guide](/README.md#guide--documentation)

# Gotchas / anti-patterns

Known footguns, each with **symptom → cause → fix**. Skim before debugging.

### 1. `standalone` without an explicit `path:`

- **Symptom:** `undefined method '..._comp_path'`, or no route generated for the component.
- **Cause:** `standalone` only emits a route when a `path:` is given.
- **Fix:** Always pass `standalone path: 'users/show/:id' do ... end`. A component with no
  standalone is valid but must be nested in another component (has no URL).

### 2. `render_intent` / `render_sub_comp` output not appearing

- **Symptom:** The button/list silently missing from the rendered page.
- **Cause:** Dyny does not auto-print return values. `render_intent` returns an HTML string.
- **Fix:** Wrap it: `concat render_intent(:edit, user)` (Dyny's equivalent of `<%= %>`).

### 3. Overriding `respond` skips authorization

- **Symptom:** An endpoint is reachable without the expected permission check.
- **Cause:** `authorize` is evaluated inside the *default* `respond`. A custom `respond`
  (especially the `nil`/all-formats one) replaces it.
- **Fix:** Re-check authorization yourself inside the custom `respond`, or keep a separate
  default `respond` for the relevant format.

### 4. `schema_field` with the foreign key name

- **Symptom:** Association param rejected by Schemacop / not assigned.
- **Cause:** Compony adds `_id` for associations automatically.
- **Fix:** Use the **association name**: `schema_field :author`, not `schema_field :author_id`.
  Same for `field :author` in `form_fields`.

### 5. Model without `label`

- **Symptom:** Errors or blank text when Compony renders titles/links for the model.
- **Cause:** Compony calls `model.label` for display everywhere.
- **Fix:** Implement `def label` on every Compony model (or have a `label` column).

### 6. Forgetting to forward args in a custom `initialize`

- **Symptom:** `parent_comp`, `@data`, comp opts mysteriously `nil`; nesting broken.
- **Cause:** The base initializer wires essential state. Skipping `super` drops it.
- **Fix:** Call `super(*args, **kwargs, &block)` first, then set your own ivars. Prefer
  putting logic in `setup` instead of overriding `initialize`.

### 7. Reading a label without its block argument

- **Symptom:** `wrong number of arguments` from a label block.
- **Cause:** Resourceful components' label blocks take the model; non-resourceful take none.
- **Fix:** `label(User.first)` for resourceful; `label` (no arg) otherwise. At most one arg.

### 8. `content :name` inside a block tries to render another component's block

- **Symptom:** Content block not found / unexpected output.
- **Cause:** Nested `content :name` only renders a block defined in the **same** component.
- **Fix:** To embed another component use `render_sub_comp`, not nested `content`.

### 9. Multiple pages in one component

- **Symptom:** Tangled `standalone`/`verb`/`respond` tree, confusing routes.
- **Cause:** Extra `standalone` calls are for *companion* endpoints (AJAX tiles, autocomplete
  JSON) of the *same* screen — not for separate pages.
- **Fix:** One screen = one component exposing one main route. Make another component for
  another page.

### 10. Resourceful component on a path without `:id`

- **Symptom:** `Couldn't find <Model> without an ID` (e.g. an Index at `/users`).
- **Cause:** Default `load_data` does `data_class.find(params[:id])`.
- **Fix:** Override `load_data { @data = User.all }` (or your scope) for collection/index
  components.

### 11. `redirect_to` with a hardcoded path

- **Symptom:** Links break after renaming/moving a component.
- **Cause:** Bypassing the intent system.
- **Fix:** Use `redirect_to Compony.path(:index, :users)` / `Compony.path(:show, @data)`.

### 12. ActiveStorage attachment on a virtual model

- **Symptom:** Uploaded file not persisted for a `Compony::VirtualModel`.
- **Cause:** Virtual models aren't backed by a real table; the default `store_data` save
  doesn't persist attachments.
- **Fix:** Override `store_data` to only validate (`@create_succeeded = @data.validate`) and
  perform the real mutation/attachment in `on_created_respond`. See
  [virtual_models.md](/doc/guide/virtual_models.md).

### 13. `tailwindcss-rails` purges Compony styles

- **Symptom:** Compony component markup unstyled in production.
- **Cause:** Tailwind's unused-CSS purge doesn't scan component classes (their HTML isn't in
  `app/views`).
- **Fix:** Safelist the classes, or don't use `tailwindcss-rails` with Compony (see
  README "Caveats").

### 14. Public endpoint still 401/redirecting

- **Symptom:** Webhook/public action blocked by app auth or CSRF.
- **Cause:** `skip_authentication!` alone doesn't remove CSRF, and `authorize` is still
  mandatory.
- **Fix:** In the standalone: `skip_authentication!` + `skip_forgery_protection!`, and in
  the verb `authorize { true }` (then validate a bearer token yourself).

### 15. Hand-rolled endpoint where a pre-built CRUD component exists

- **Symptom:** A custom `Compony::Component` with manual `button_to`/standalone for
  delete/edit/create, duplicating routing, authorization, confirmation UI, styling.
- **Cause:** Reaching for a bespoke component instead of the pre-built one.
- **Fix:** For CRUD use the pre-built parents (`Destroy`/`Edit`/`New`/`Show`/`Index`) and
  point with `render_intent(:destroy, record)`. Reserve custom `Compony::Component`
  standalones for genuinely non-CRUD actions (job dispatch, webhooks, multi-record ops).
  Put a resourceful component in the family of the model it operates on, not the family
  it is navigated from; pass parent context via path params.

### 16. `attr_accessor` on a model for form-only fields

- **Symptom:** Virtual form fields declared as `attr_accessor` on the ActiveRecord model.
- **Cause:** Polluting the persistent model with form-only concerns.
- **Fix:** Use an `ActiveType::Record[Model]` (or `Compony::VirtualModel`) inner class on
  the component with `ar_attribute` + `field`, and set `data_class` to it. See
  [virtual_models.md](/doc/guide/virtual_models.md).

[Guide index](/README.md#guide--documentation)
