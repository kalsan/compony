[Back to the guide](/README.md#guide--documentation)

# Resourceful components

So far, we have mainly seen how to present static content, without considering how loading and storing data is handled. Whenever a component is about data, be it a collection (e.g. index, list) or a single instance (e.g. new, show, edit, destroy, form), that component typically becomes resourceful. In order to implement a resourceful component, include the mixin `Compony::ComponentMixins::Resourceful`.

Resourceful components use an instance variable `@data` and provide a reader `data` for it. As a convention, always store the data the component "is about" in this variable.

Further, the class of which `data` should be can be specified and retrieved by using `data_class`. By default, `data_class` is inferred from the component's family name, i.e. `Components::User::Show` will automatically return `User` as `data_class`.

The mixin adds extra hooks that can be used to store logic that can be executed in the request context when the component is rendered standalone. The formulation of that sentence is important, as the decision which of these blocks are executed depends on the verb DSL. But before elaborating on that, let's first look at all the available hooks provided by the Resourceful mixin:

- `load_data`: Important. Specify a block that assigns something to `@data` here. The block will be run before authorization - thus, you can check `@data` for authorizing (e.g. `can?(:read, @data)`).
- `after_load_data`: Optional. If a block is specified, it is run immediately after `load_data`. This is useful if you inherit from a component that loads data but you need to alter something, e.g. refining a collection.
- `assign_attributes`: Important for components that alter data, e.g. New, Edit. Specify a block that assigns attributes to your model from `load_data`. The model is now dirty, which is important: **do not save your model here**, as authorization has not yet been performed. Also, **do not forget to validate params before assigning them to attributes**.
- `after_assign_attributes`: Optional. If a block is specified, it is run immediately after `assign_attributes`. Its usage is similar to that of `after_load_data`.
- (At this point, your `authorize` block is executed, throwing a `CanCan::AccessDenied` exception causing HTTP 403 not authorized if the block returns false.)
- `store_data`: Important for components that alter data, e.g. New, Edit. This is where you save your model stored in `@data` to the database.

Another important aspect of the Resourceful mixin is that it also **extends the Verb DSL** available in the component. The added calls are:

- `load_data`
- `assign_attributes`
- `store_data`

Unlike the calls above, which are global for the entire component, the ones in the Verb DSL are on a per-verb basis, same as the `authorize` call. If the same hook is both given as a global hook and in the Verb DSL, the Verb DSL hook overwrites the global one. The rule of thumb on where to place logic is:

- If multiple verbs use the same logic for a hook, place it in the global hook. For example, let us consider an Edit component: if GET is called on it, the model is loaded and parameters are assigned to it in order to fill the form's inputs. If PATCH is called, the exact same thing is done before attempting to save the model. In this case, you would implement both `load_data` and `assign_attributes` as global hooks.
- If a hook is specific to a single verb, place it in the verb config.

Let's build an example of a simplified Destroy component. In practice, you'd instead inherit from `Compony::Components::Destroy`. However, for the sake of demonstration, we will implement it from scratch:

```ruby
class Components::Users::Destroy < Compony::Component
  # Make the component resourceful
  include Compony::ComponentMixins::Resourceful

  setup do
    # Let the path be of the form users/42/destroy
    standalone path: 'users/:id/destroy' do
      verb :get do
        # In the case of a GET request, ask for confirmation, not deleting anything.
        # Nevertheless, we should authorize :destroy, not :read.
        # Reason: this way, buttons pointing to this component will not be shown
        # to users which lack the permission to destroy @data.
        authorize { can?(:destroy, @data) }
      end

      verb :delete do
        # In the case of a DELETE request, the record will be destroyed.
        authorize { can?(:destroy, @data) }
        store_data { @data.destroy! }
        # We overwrite the respond block because we want to redirect, not render
        respond do
          flash.notice = "#{@data.label} was deleted."
          redirect_to Compony.path(:index, :users)
        end
      end
    end

    # Resourceful components have a default `load_data` block that loads the model.
    # Therefore, the default behavior is already set to:
    # load_data { @data = User.find(params[:id]) }

    label(:short) { |_| 'Delete' }
    label(:long) { |data| "Delete #{data.label}" }
    content do
      h1 "Are you sure to delete #{@data.label}?"
      div render_intent(:destroy, @data, label: 'Yes, delete', method: :delete)
    end
  end
end
```

## Complete resourceful lifecycle

This graph documents a typical resourceful lifecycle according to which Compony's [pre-built components](./pre_built_components.md) are implemented.

- `load_data` creates or fetches the resource from the database.
- `after_load_data` can refine the resource, e.g. add scopes to a relation.
- `assign_attributes` takes the HTTP parameters, validates them and assigns them to the resource.
- `after_assign_attributes` can refine the assigned resource, e.g. provide defaults for blank attributes.
- `authorize` is called.
- `store_data` creates/updates/destroys the resource.
- `respond` typically shows a flash and redirects to another component.

![Graph of the complete resourceful lifecycle](/doc/resourceful_lifecycle.png)

## Nesting resourceful components

As mentioned earlier, hooks such as those provided by Resourceful typically run only when a component is accessed standalone. This means that in a nested setting, only the component running those hooks is the root component.

When nesting resourceful components, it is therefore best to load all necessary data in the root component. Make sure to include any relations used by sub-components in order to avoid "n+1" queries in the database.

`resourceful_sub_comp` is the resourceful sibling of `sub_comp` and both are used the same way. Under the hood, the resourceful call passes two extra parameters to the sub component: `data` and `data_class`.

The rule of thumb thus becomes:

- When a resourceful component instantiates a resourceful sub-component, use `resourceful_sub_comp` in the parent component.
- When a resourceful component instantiates a non-resourceful sub-component, use `sub_comp`.
- The situation where a non-resourceful component instantiates a resourceful component should not occur. Instead, make your parent component resourceful, even if it doesn't use the data itself. By housing a resourceful sub-comp, the parent component's nature inherently becomes resourceful and you should use the Resourceful mixin.

[Guide index](/README.md#guide--documentation)