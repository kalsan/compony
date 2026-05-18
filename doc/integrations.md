[Back to the guide](/README.md#guide--documentation)

# Integrations & companion gems

What Compony pulls in, what it optionally lights up, and what you are expected to add
yourself. The authoritative source for hard dependencies and their version constraints is
the `:gemspec` task in [`Rakefile`](/Rakefile) (it generates `compony.gemspec`); the table
below mirrors it and must be updated together with it (see
[maintaining.md](/doc/guide/maintaining.md)).

## Hard runtime dependencies (installed automatically)

| Gem | Constraint | Why Compony needs it |
| --- | --- | --- |
| `rails` | `>= 7.2.1` | Routing, controllers, views Compony plugs into. |
| `request_store` | `>= 1.7` | Per-request storage (e.g. `Compony.root_comp`). |
| `dyny` | `>= 0.0.3` | HTML-as-Ruby templating used in `content` blocks. |
| `schemacop` | `>= 3.0.17` | Strong-param schema validation behind `schema_field` / `schema_line`. |
| `simple_form` | `>= 5.3.1` | The form builder behind the Form component's `field`. |
| `dslblend` | `>= 0.0.3` | Powers the `RequestContext` multi-provider DSL. |
| `anchormodel` | `>= 0.3.0` | `anchormodel` model-field type + enum-like associations. |
| `cancancan` | `~> 3.6.1` | Authorization: `authorize { can?(...) }`, `accessible_by`, per-field `permitted_attributes`. |

The Ruby floor is `>= 3.3.5` (`required_ruby_version`).

> Version note: the gemspec requires `rails >= 7.2.1`. If the README's prose mentions an
> older range, the gemspec wins — keep them in sync when bumping (see maintaining.md).

## Optional — presence unlocks a feature

These are **not** declared dependencies; Compony detects them and enables behavior if they
are in the host app's bundle.

| Gem | Unlocks |
| --- | --- |
| `active_type` | `Compony::VirtualModel` (loaded only if `ActiveType::Object` is defined). Non-persistent / upload / wizard forms — [patterns §12](/doc/guide/patterns.md#12-virtual-model-for-non-persistent--upload-forms), [virtual_models.md](/doc/guide/virtual_models.md). |
| `ransack` | List filtering, sorting links and the sort select in [`List`](/doc/guide/pre_built_components/list.md). Without it, declare no `filter`/`sort` and those UIs stay off. |

## App-side companions (you add these)

Compony is UI- and auth-agnostic; these are conventional choices in real apps, pulled in
by your app, not by Compony.

| Concern | Typical choice | Used by |
| --- | --- | --- |
| Authentication | Devise, or a custom login component + `Compony.authentication_before_action=` | Compony ships **no** auth ([README](/README.md)); token-link flows → [patterns §18](/doc/guide/patterns.md#18-signed-token-capability-links-auth-less-onboarding--magic-links) |
| Turbo / Stimulus | `turbo-rails`, `stimulus-rails` | Compony fully supports Turbo Drive; inline-edit → [patterns §15](/doc/guide/patterns.md#15-inline-edit-card-with-a-turbo-frame), ajax PATCH → [patterns §17](/doc/guide/patterns.md#17-inline-patch-without-a-form-reorder--quick-toggle) |
| Select / date inputs | TomSelect, Flatpickr (as registered `simple_form` inputs) | `field(:x, as: :tom_select/:flatpickr_*)` — [patterns §5–6](/doc/guide/patterns.md#5-custom-form--schemacop-kept-in-sync) |
| i18n | Rails I18n and/or FastGettext | Component labels; gem ships `config/locales/{de,en,fr}.yml` |
| File handling | ActiveStorage (+ a variant/processor) | Attachment fields, virtual-model uploads — [patterns §12](/doc/guide/patterns.md#12-virtual-model-for-non-persistent--upload-forms) |
| PDF / CSV | Prawn / wicked_pdf, Ruby `CSV` | Export endpoints — [patterns §10](/doc/guide/patterns.md#10-csv--pdf-via-respond-format) |
| Signed tokens | `jwt` | Capability links — [patterns §18](/doc/guide/patterns.md#18-signed-token-capability-links-auth-less-onboarding--magic-links) |

Incompatibility: `tailwindcss-rails` purges Compony component CSS (component HTML is not in
`app/views`); see [gotchas.md #13](/doc/guide/gotchas.md#13-tailwindcss-rails-purges-compony-styles).

## Development dependencies

`yard >= 0.9.28` (docs), `rubocop >= 1.48`, `rubocop-rails >= 2.18.0` (lint).

[Guide index](/README.md#guide--documentation)
