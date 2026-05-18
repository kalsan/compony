[Back to the guide](/README.md#guide--documentation)

# Cookbook

Task-oriented entry point: "I want to do X — where is it?". Every recipe lives in
[Real-world patterns](./patterns.md) or the guide; this page is a pure index by goal so
you don't need to know a pattern's name. Nothing is duplicated here — only links.

## Recipes by task

| I want to… | See |
| --- | --- |
| Share layout/chrome across all components | [patterns §1 base layer](./patterns.md#1-the-app-base-component-layer) |
| Add a CRUD screen with almost no code | [patterns §2 thin leaves](./patterns.md#2-thin-leaf-components), [example.md](./example.md) |
| List records with columns/filters/sorts | [List](./pre_built_components/list.md), [patterns §3–4](./patterns.md#3-index--load_data-scope--nested-list) |
| Scope/order what an Index shows | [patterns §3](./patterns.md#3-index--load_data-scope--nested-list) (`load_data`) |
| Embed a child list inside a Show | [patterns §4](./patterns.md#4-list-customization), [nesting.md](./nesting.md) |
| Build a custom form + strong params | [patterns §5](./patterns.md#5-custom-form--schemacop-kept-in-sync), [Form](./pre_built_components/form.md) |
| Nested attributes in a form | [patterns §5](./patterns.md#5-custom-form--schemacop-kept-in-sync), [example_advanced.md](./example_advanced.md) |
| Autocomplete / ajax select field | [patterns §6](./patterns.md#6-autocomplete-form-app-level-subclass) |
| Split a detail page into tabs | [patterns §7](./patterns.md#7-tabbed-show-via-a-mixin) |
| Prefill/derive fields before save | [patterns §8](./patterns.md#8-lifecycle-hooks-for-derived-data) (`after_assign_attributes`) |
| Guard/redirect before rendering | [patterns §8](./patterns.md#8-lifecycle-hooks-for-derived-data), [basic_component.md](./basic_component.md#redirecting-away--intercepting-rendering) |
| Customize the action toolbar | [patterns §9](./patterns.md#9-exposed-intents-as-the-action-toolbar), [intents.md](./intents.md#exposed-intents) |
| Disable a button with a reason | [feasibility.md](./feasibility.md), [patterns §9](./patterns.md#9-exposed-intents-as-the-action-toolbar) |
| Export CSV / PDF | [patterns §10](./patterns.md#10-csv--pdf-via-respond-format) |
| Launch a background job from a button | [patterns §11](./patterns.md#11-non-crud-job-dispatch-toggles-clone) |
| Toggle a boolean (activate/lock/…) | [patterns §11](./patterns.md#11-non-crud-job-dispatch-toggles-clone) |
| Clone/duplicate a record | [patterns §11](./patterns.md#11-non-crud-job-dispatch-toggles-clone) |
| Non-persistent / upload-only form | [patterns §12](./patterns.md#12-virtual-model-for-non-persistent--upload-forms), [virtual_models.md](./virtual_models.md) |
| Public page / inbound webhook | [patterns §13](./patterns.md#13-public-endpoints--webhooks), [gotchas §14](./gotchas.md#14-public-endpoint-still-401redirecting) |
| Custom button look | [patterns §14](./patterns.md#14-custom-button-style), [intents.md](./intents.md#adding-your-own-styles) |
| Inline-edit a card without a full page | [patterns §15 turbo-frame inline edit](./patterns.md#15-inline-edit-card-with-a-turbo-frame) |
| Multi-step wizard across components | [patterns §16 multi-step wizard](./patterns.md#16-multi-step-wizard-across-components) |
| Reorder/inline-patch without a form | [patterns §17 inline PATCH](./patterns.md#17-inline-patch-without-a-form-reorder--quick-toggle) |
| Magic-login / invite / reset / confirm link (no session) | [patterns §18 signed-token capability links](./patterns.md#18-signed-token-capability-links-auth-less-onboarding--magic-links) |

If a goal isn't listed, check the [DSL reference](./dsl_reference.md) and
[glossary](./glossary.md).

[Guide index](/README.md#guide--documentation)
