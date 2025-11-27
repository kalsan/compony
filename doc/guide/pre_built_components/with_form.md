- [Back to the guide](/README.md#guide--documentation)
- [List of pre-built components](/doc/guide/pre_built_components.md)

# Pre-built components: WithForm

`Compony::Components::WithForm` is an abstract base class for components that render a form. Those components can further be resourceful, but don't have to be. If a component inherits from WithForm, it is always twinned with another component that will provide the form.

WithForm adds the following DSL methods:

- `form_comp_class` sets the class that will be instantiated by `form_comp`
- `form_comp` returns an instance of the Form component twinned with this component. If `form_comp_class` was never set, it will default to loading the component named `Form` in the same family as this component.
- `submit_verb` takes a symbol containing a verb, e.g. `:patch`. It defines this component's standalone verb that should be called when the twinned Form component is submitted.
- `submit_path` defaults to this component's standalone path. You can override this to submit the form to another component, should you need it.

The following other pre-built components implement `WithForm`:

- [`New`](new.md)
- [`Edit`](edit.md)