- [Back to the guide](/README.md#guide)
- [List of pre-built components](/doc/guide/pre_built_components.md)

# Pre-built components: New

This component is the Compony equivalent to a typical Rails controller's `new` and `create` actions.

`Compony::Components::New` is a resourceful standalone component based on [`WithForm`](./with_form.md) that listens to two verbs:

- GET will cause the New component to create a fresh instance of its `data_class` and render the form.
- POST (equivalent to a `create` action in a controller) will attempt to save the resource. If that fails, the form is rendered again with a HTTP 422 code ("unprocessable entity"). If the creation succeeds, a flash is shown and the user is redirected:
  - if present: the data's Show component
  - otherwise, if the resource is owned by another resource class: the owner's Show component
  - otherwise, the data's Index component

Authorization checks for `create` even in GET. The reason is that it makes no sense to present an empty form to a user who cannot create a new record. This also causes any `compony_link` and `compony_button` to New components to be hidden to users lacking the permission.

This component follows the [resourceful lifecycle](/doc/guide/resourceful.md#complete-resourceful-lifecycle). `load_data` is set to create a new record and `store_data` attempts to create it. Parameters are validated in `assign_attributes` using a Schemacop schema that is generated from the form. The schema corresponds to Rail's typical strong parameter structure for forms. For example, a user's New component would look for a parameter `user` holding a hash of attributes (e.g. `user[first_name]=Tom`).

In case you overwrite `store_data`, make sure to set `@create_succeeded` to true if storing was successful (and to set it to false otherwise).

The following DSL calls are implemented to allow for convenient overrides of default logic:

- The block `on_create_failed_respond` is run if `@create_succeeded` is not true. By default, it logs all error messages with level `warn` and renders the component again through HTTP 422, causing Turbo to correctly display the page. Error messages are displayed by the form inputs.
- The block `on_created` is evaluated between successful record creation and responding. By default, it is not implemented and doing so is optional. This would be a suitable location for hooks that update state after a resource was created (like an `after_create` hook, but only executed if a record was created by this component). Do not redirect or render here, use the next blocks instead.
- The block given in `on_created_respond` is evaluated after successful creation and by default shows a flash, then redirects. Overwrite this block if you need to completely customize all logic that happens after creation. If this block is overwritten, `on_created_redirect_path` will not be called.
- `on_created_redirect_path` is evaluated as the second step of `on_created_respond` and redirects to the resource's Show, its owner's Show, or its own Index component as described above. Overwrite this block in order to redirect ot another component instead, while keeping the default flash provided by `on_created_respond`.
