- [Back to the guide](/README.md#guide)
- [List of pre-built components](/doc/guide/pre_built_components.md)

# Pre-built components: Destroy

This component is the Compony equivalent to a typical Rails controller's `destroy` action.

`Compony::Components::Destroy` is a resourceful standalone component that listens to two verbs:

- GET will cause the Destroy component to ask if the resource should be destroyed, along with a button pointing to the DELETE verb. If the record does not exist, a HTTP 404 code is returned.
- DELETE will `destroy!` the resource, show a flash and redirect to:
  - if present: the data's Show component
  - otherwise: the data's Index component

Authorization checks for `destroy` even in GET. The reason is that users that aren't able to destroy a resource shouldn't even arrive at the page asking them whether they want to do so, unable to click the only button due to lacking permissions. This also causes any [intents](/doc/guide/intents.md) to Destroy components to be hidden if the user is unable to destroy the corresponding resource.

This component largely follows the [resourceful lifecycle](/doc/guide/resourceful.md#complete-resourceful-lifecycle). As can be expected, the resource is loaded by `Resourceful`'s default load block and `store_data` is implemented to destroy the resource.

If the resource is [owned](/doc/guide/ownership.md), the component provides a `:back_to_owner` [exposed intent](/doc/guide/intents.md#exposed-intents) in the form of a cancel button.

The following DSL methods are implemented to allow for convenient overrides of default logic:

- The block `on_destroyed` is evaluated between successful record destruction and responding. By default, it is not implemented and doing so is optional. This would be a suitable location for hooks that update state after a resource was destroyed (like an `after_destroy` hook, but only executed if a record was destroyed by this component). Do not redirect or render here, use the next blocks instead.
- The block given in `on_destroyed_respond` is evaluated after destruction and by default shows a flash, then redirects. The redirection is performed with HTTP code 303 ("see other") in oder to force a GET request. This is required for the component to work with Turbo. Overwrite this block if you need to completely customize all logic that happens after destruction. If this block is overwritten, `on_destroyed_redirect_path` will not be called.
- `on_destroyed_redirect_path` is evaluated as the second step of `on_destroyed_respond` and redirects to the resource's Show or Index component as described above. Overwrite this block in order to redirect to another component instead, while keeping the default flash provided by `on_destroyed_respond`.