- [Back to the guide](/README.md#guide)
- [List of pre-built components](/doc/guide/pre_built_components.md)

# Pre-built components: Edit

This component is the Compony equivalent to a typical Rails controller's `edit` and `update` actions.

`Compony::Components::Edit` is a resourceful standalone component based on [`WithForm`](./with_form.md) that listens to two verbs:

- GET will cause the Edit component to load a record given by ID and render the form based on that record. If the record does not exist, a HTTP 404 code is returned.
- PATCH (equivalent to a `update` action in a controller) will attempt to save the resource. If that fails, the form is rendered again with a HTTP 422 code ("unprocessable entity"). If the update succeeds, a flash is shown and the user is redirected:
  - if present: the data's Show component
  - otherwise, if the resource is owned by another resource class: the owner's Show component
  - otherwise, the data's Index component

Unlike in New and Destroy, Edit's authorization checks for `edit` in GET and for `update` in PATCH. This enables you to "abuse" an Edit component to double as a Show component. Users having only `:read` permission will not see any links or buttons pointing to an Edit component. Users having only `:edit` permissions can see the form (including the data) but not submit it. Users having `:write` permissions can edit and update the Resource, in accordance to CanCanCan's `:write` alias.

This component follows the [resourceful lifecycle](/doc/guide/resourceful.md#complete-resourceful-lifecycle). Parameters are validated in `assign_attributes` using a Schemacop schema that is generated from the form. The schema corresponds to Rail's typical strong parameter structure for forms. For example, a user's Edit component would look for a parameter `user` holding a hash of attributes (e.g. `user[first_name]=Tom`).

In case you overwrite `store_data`, make sure to set `@update_succeeded` to true if storing was successful (and to set it to false otherwise).

The following DSL calls are implemented to allow for convenient overrides of default logic:

- The block `on_update_failed_respond` is run if `@update_succeeded` is not true. By default, it logs all error messages with level `warn` and renders the component again through HTTP 422, causing Turbo to correctly display the page. Error messages are displayed by the form inputs.
- The block `on_updated` is evaluated between successful record creation and responding. By default, it is not implemented and doing so is optional. This would be a suitable location for hooks that update state after a resource was updated (like an `after_update` hook, but only executed if a record was updated by this component). Do not redirect or render here, use the next blocks instead.
- The block given in `on_updated_respond` is evaluated after successful creation and by default shows a flash, then redirects. Overwrite this block if you need to completely customize all logic that happens after creation. If this block is overwritten, `on_updated_redirect_path` will not be called.
- `on_updated_redirect_path` is evaluated as the second step of `on_updated_respond` and redirects to the resource's Show, its owner's Show, or its own Index component as described above. Overwrite this block in order to redirect ot another component instead, while keeping the default flash provided by `on_updated_respond`.
