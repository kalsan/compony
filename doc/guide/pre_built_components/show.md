- [Back to the guide](/README.md#guide)
- [List of pre-built components](/doc/guide/pre_built_components.md)

# Pre-built components: Show

This resourceful component corresponds to a typical Rails controller's `show` action and presents `@data` which is typically a model instance.

To use it, create a component of the style `Components::Users::Show` and inherit from `Compony::Components::Show`. By default, this will display all permitted fields along with their labels. Consult the component's class to learn about the methods you can use in `setup` in order to customize the behavior.