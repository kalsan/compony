[Back to the guide](/README.md#guide--documentation)

# Glossary

One-line definitions of Compony vocabulary. Deeper treatment is linked.

| Term | Definition |
| --- | --- |
| **Component** | A Ruby class (`Components::Family::Name`) bundling a route, controller action and view. See [basic_component.md](/doc/guide/basic_component.md). |
| **Family** | The plural namespace grouping a model's components, analogous to a Rails controller (`Users`). |
| **Comp name** | The component's own name, analogous to a Rails action (`show`). |
| **`setup`** | Class-level block holding nearly all component config; parent's runs before child's. |
| **Content block** | A named (`:main` default) view block rendered via Dyny inside a RequestContext. |
| **`before_render`** | Hook chain run before content; if it sets a response body (e.g. redirect) content is skipped. |
| **Standalone** | A `standalone` config that makes Compony emit a Rails route for the component. See [standalone.md](/doc/guide/standalone.md). |
| **Standalone name** | Identifier for one of several routes a component exposes; `nil` = the main one. |
| **Verb** | An HTTP method config inside a standalone (`verb :get do ... end`). |
| **`authorize`** | Mandatory per-verb block; truthy grants access, falsy raises `CanCan::AccessDenied`. |
| **`respond`** | Per-verb block overriding the controller response; overriding it skips the default authorize step. |
| **Resourceful** | A component that auto-loads a record/relation into `@data` (mixin or pre-built parent). See [resourceful.md](/doc/guide/resourceful.md). |
| **`@data`** | The record (or AR relation) a resourceful component operates on. |
| **`data_class`** | The model class a resourceful component expects; defaults from the family name. |
| **Lifecycle hooks** | `load_data → after_load_data → authorize → assign_attributes → after_assign_attributes → store_data`. |
| **Intent** | A gateway object to a target component carrying context (model, path, feasibility, label). See [intents.md](/doc/guide/intents.md). |
| **Exposed intent** | An intent a component declares for its parent/layout to render (e.g. an actions toolbar). |
| **`Compony.path`** | Helper that builds a Rails path string via an intent (use for redirects). |
| **`render_intent`** | Content/view helper that renders a link or button to another component. |
| **`render_sub_comp`** | Content helper that instantiates and nests another component. |
| **Sub comp / parent comp** | A component instantiated inside another; the outer one is its `parent_comp`. |
| **Root comp** | The top component of the current render tree (no parent); `Compony.root_comp`. |
| **RequestContext** | Dslblend object content blocks run in: providers are the component, controller, helpers. See [internal_datastructures.md](/doc/guide/internal_datastructures.md). |
| **Backfire** | Dslblend mechanism copying instance vars set in a block back onto the component. |
| **Button / style** | A presenter component for an intent; `style` (`:css_button`, `:link`, custom) selects the class. |
| **Feasibility** | Framework where model `prevent` blocks disable buttons/links to an action with a reason. See [feasibility.md](/doc/guide/feasibility.md). |
| **`prevent`** | Model class DSL declaring a feasibility prevention for one or more actions. |
| **Field** | A model-level declaration (`field :name, :type`) of a UI-relevant attribute and its formatting. See [model_fields.md](/doc/guide/model_fields.md). |
| **Ownership / `owned_by`** | Declares a model conceptually part of another, adjusting redirects/top actions. See [ownership.md](/doc/guide/ownership.md). |
| **Virtual model** | A non-persistent ActiveType-backed model usable as a form target. See [virtual_models.md](/doc/guide/virtual_models.md). |
| **Dyny** | The HTML-as-Ruby templating gem content blocks are written in ([repo](https://github.com/kalsan/dyny)). |
| **Abstract component** | A component never routed directly, only inherited from (e.g. an app's `BaseComponents::*`). |

[Guide index](/README.md#guide--documentation)
