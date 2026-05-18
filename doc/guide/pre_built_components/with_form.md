- [Back to the guide](/README.md#guide--documentation)
- [List of pre-built components](/doc/guide/pre_built_components.md)

# Pre-built components: WithForm

`Compony::Components::WithForm` is the abstract base for components that render and submit
a form. It is **twinned** with a [`Form`](./form.md) component: WithForm provides the
route, authorization and resource handling; the Form provides the inputs and param schema.
[`New`](./new.md) and [`Edit`](./edit.md) both inherit from WithForm — you rarely subclass
it directly, but understanding the twinning explains how they work.

A WithForm component may be resourceful (New/Edit are) but does not have to be.

## How the twinning works

- `form_comp` returns the Form instance, built lazily. It defaults to the component named
  `Form` in the **same family**, instantiated with this component as `parent_comp` and
  passed `submit_verb`, `submit_path` and `cancancan_action`.
- The Form renders inside this component's `content` (e.g. New/Edit do
  `concat form_comp.render(controller, data: @data)`).
- The form's `<form>` posts back to `submit_path` using `submit_verb`; that same component
  handles the submit verb (POST for New, PATCH for Edit) and runs the resourceful
  lifecycle (`assign_attributes` → `store_data` → `respond`).

## DSL methods

| Method | Signature | Description |
| --- | --- | --- |
| `submit_verb` | `submit_verb(:patch)` | HTTP verb the twinned form submits with. Mandatory (New sets `:post`, Edit `:patch`). |
| `form_comp_class` | `form_comp_class(Components::Users::SignupForm)` | Use a specific Form class instead of the same-family `Form`. |
| `submit_path` | `submit_path { Compony.path(:create, :users) }` | Override where the form submits. Block is given the controller; defaults to this component's own path. |
| `form_cancancan_action` | `form_cancancan_action(:edit)` | CanCanCan action used by the Form for per-field `permitted_attributes` (New sets `:new`, Edit `:edit`). Pass `nil` to disable per-field auth. |
| `form_comp` | `form_comp` | (Not DSL — a reader.) The Form instance; override in a subclass for full control. |

## Example: a custom non-default form

```ruby
class Components::Users::Signup < Compony::Components::New
  setup do
    standalone path: 'signup' do
      skip_authentication!
      verb :get  do authorize { true } end
      verb :post do authorize { true } end
    end
    form_comp_class Components::Users::SignupForm   # not the default Users::Form
    on_created_redirect_path { Compony.path(:show, @data) }
  end
end

class Components::Users::SignupForm < Compony::Components::Form
  setup do
    form_fields do
      concat field(:email)
      concat pw_field(:password)
    end
    schema_field :email
    schema_pw_field :password
  end
end
```

For the full submit/redirect behavior see [`New`](./new.md) and [`Edit`](./edit.md); for
the form input/schema DSL see [`Form`](./form.md); for the lifecycle hooks see
[Resourceful](/doc/guide/resourceful.md). Multi-step and clone flows that reuse this
machinery are in [Real-world patterns](../patterns.md#11-non-crud-job-dispatch-toggles-clone).