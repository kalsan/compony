# Compony — agent primer

Compony is a Ruby on Rails gem. A **component** = one Ruby class that exports a route, a
controller action, and a view (written in [Dyny](https://github.com/kalsan/dyny), HTML as
Ruby). Components are subclassable, so views and controller logic inherit like normal Ruby.

This file orients coding agents. Humans: start at [README.md](/README.md).

## Mental model in 6 sentences

1. A component lives at `app/components/<family>/<comp>.rb` as `Components::<Family>::<Comp>`.
   Family = pluralized model/controller name (`Users`); comp = action name (`Show`).
2. Almost all behavior goes inside a `setup do ... end` block; subclass `setup` runs after
   parent `setup`, so children override parents.
3. `standalone path: '...' do verb :get do authorize { ... } end end` generates the Rails
   route. No `standalone` → component must be nested in another, has no URL.
4. `content do ... end` is the view, evaluated in a `RequestContext` (Dyny + controller
   helpers + component as `self`-ish providers).
5. Resourceful components (`include Compony::ComponentMixins::Resourceful` or inherit a
   pre-built one) auto-load a record into `@data` from `params[:id]`.
6. Point between components with **intents**: `Compony.path(:show, model)` for redirects,
   `render_intent(:edit, model)` for buttons/links inside content.

## Public API surface (the `Compony.*` module methods)

| Symbol | Purpose |
| --- | --- |
| `Compony.intent(...)` | Build an `Intent` (gateway to a component). |
| `Compony.path(comp, model_or_family, **)` | Rails path string. Use for redirects. |
| `Compony.comp_class_for(:show, family)` | Returns comp class or `nil` (existence check). |
| `Compony.comp_class_for!(...)` | Same, raises if missing. |
| `Compony.root_comp` | Currently rendered root component (use in layout). |
| `Compony.family_name_for(model_or_sym)` | Resolve family name. |
| `Compony.register_button_style(:name, 'Class')` | Register a button style. |
| `Compony.default_button_style=(:name)` | Set default button style. |
| `Compony.authentication_before_action=(sym)` | Hook app auth into Compony. |
| `Compony.content_before_root_comp { }` / `_after_` | Inject markup around root comp. |
| `Compony.model_field_namespaces=([...])` | Add custom model-field type classes. |

Set the config setters in `config/initializers/compony.rb`.

## Where to read what

| You need to… | Read |
| --- | --- |
| Full DSL method list with signatures | [doc/guide/dsl_reference.md](/doc/guide/dsl_reference.md) |
| Definition of a Compony term | [doc/guide/glossary.md](/doc/guide/glossary.md) |
| Avoid a known footgun | [doc/guide/gotchas.md](/doc/guide/gotchas.md) |
| A simple end-to-end app | [doc/guide/example.md](/doc/guide/example.md) |
| A realistic app (custom form, virtual fields, CSV, feasibility) | [doc/guide/example_advanced.md](/doc/guide/example_advanced.md) |
| Routing | [doc/guide/standalone.md](/doc/guide/standalone.md) |
| Linking between components | [doc/guide/intents.md](/doc/guide/intents.md) |
| Pre-built CRUD components | [doc/guide/pre_built_components.md](/doc/guide/pre_built_components.md) |
| Companion gems (required/optional/app-side) | [doc/integrations.md](/doc/integrations.md) |
| Release & docs policy (working on the gem) | [doc/guide/maintaining.md](/doc/guide/maintaining.md) |
| Machine-readable index of all docs | [doc/llms.txt](/doc/llms.txt) |

## Source layout

- `lib/compony.rb` — the `Compony.*` module methods (public API).
- `lib/compony/component.rb` — base `Component`: `setup`, `content`, `before_render`,
  `exposed_intents`, `sub_comp`, `render`, `path`.
- `lib/compony/component_mixins/resourceful.rb` — `@data`, `load_data`, `store_data`,
  `assign_attributes`, `after_assign_attributes`, `data_class`.
- `lib/compony/component_mixins/default/standalone/` — `standalone` / `verb` / `respond` /
  `authorize` / `skip_authentication!` / `layout` DSL.
- `lib/compony/components/` — pre-built `Show Index List New Edit Form WithForm Destroy`.
- `lib/compony/intent.rb` — `Intent`: path/label/feasibility/button rendering.
- `lib/compony/model_mixin.rb` — model side: `field`, `prevent` (feasibility), `owned_by`.
- `lib/compony/virtual_model.rb` — non-persistent ActiveType-backed models.

When a consumer app vendors the gem, source is at
`vendor/bundle/ruby/<ver>/gems/compony-<ver>/`.

## Conventions when editing this gem

- DSL methods carry a `# DSL method` comment. Keep that marker; the
  [dsl_reference.md](/doc/guide/dsl_reference.md) table mirrors it.
- Every user-facing behavior change needs a `CHANGELOG.md` entry (under `# unreleased`).
  `VERSION` ending in `.edge` means an unreleased prerelease.
- Write code matching surrounding style. RuboCop config is in `.rubocop.yml`.
- The gem ships no CSS/JS — never add styling; that is the host app's job.
- Dependencies live in the `:gemspec` Rake task (not the hand); `compony.gemspec` is
  generated. New guide page → add it to [.yardopts](/.yardopts) or it won't render.
- Full release/docs/anonymization rules: [doc/guide/maintaining.md](/doc/guide/maintaining.md).
