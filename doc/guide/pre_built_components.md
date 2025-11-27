[Back to the guide](/README.md#guide--documentation)

# Pre-built components shipped with Compony

Compony comes with a few pre-built components that cover the most common cases that can be speed up development. They are meant to be inherited from and the easiest way to do this is by using the [provided Rails generators](./generators.md) `rails g component ...`.

The pre-built components can be found in the module `Compony::Components`. As you can see, there is no Show and no Index component. The reason is that these will depend a lot on your application's UI framework (e.g. Bootstrap) and thus the benefits a UI-agnostic base component can provide are minimal. Additionally, these components are very easy to implement, as is illustrated in the example at the beginning of this documentation.

In the following, the pre-built components currently shipped with Compony are presented:

- [Show](./pre_built_components/show.md): Compony's equivalent to Rail's `show` controller action
- [Index](./pre_built_components/index.md): Compony's equivalent to Rail's `index` controller action
- [List](./pre_built_components/list.md): Compony's equivalent to Rail's `_list` partial
- [Destroy](./pre_built_components/destroy.md): Compony's equivalent to Rail's `destroy` controller action
- [WithForm](./pre_built_components/with_form.md): A base class for components containing and submitting forms
- [Form](./pre_built_components/form.md): Compony's equivalent to Rail's `_form` partial
- [New](./pre_built_components/new.md): Compony's equivalent to Rail's `new` and `create` controller action
- [Edit](./pre_built_components/new.md): Compony's equivalent to Rail's `edit` and `update` controller action

[Guide index](/README.md#guide--documentation)