[Back to the guide](/README.md#guide--documentation)

# Inheritance

Compony's key advantage is that you can write DRYer code with it. To achieve this, you are encouraged to create abstract components, implement common functionality there and inherit from them in other components.

Examples:

- Perhaps you have code shared in all of your `New` components. In this case, create `BaseComponents::New` and inherit from `Compony::Components::New`. In `setup` of your base component, you can now perform all the configurations needed. Now you may inherit from it: `class Components::Users::New < BaseComponents::New`.
- Perhaps you often implement the same kind of component, for instance an index component displaying a filterable list. In this case, create `BaseComponents::Index` and inherit as follows: `class Components::Users::Index < BaseComponents::Index`.

## Behavior

When inheriting from another component class, `setup` can be called in the child as well in order to overwrite specified configurations. The parent's `setup` block will be run first, then the child's, then the grand-child's and so on.

Omit any configuration that you want to keep from the parent class. For instance, if your parent's setup looks like this:

```ruby
setup do
  standalone path: 'foo/bar' do
    layout 'funky'
    verb :get do
      authorize { true }
    end
  end
  content do
    h1 'Test'
  end
end
```

Assuming you want to implement a child class that only differs by layout and adds more content below "test", you can implement:

```ruby
setup do
  standalone do
    layout 'dark'
  end
  content :below do
    para 'This will appear below "Test".'
  end
end
```

## Un-exposing a component

If a component's parent class is [standalone](./standalone.md) but the child should not be, use `clear_standalone!`:

```ruby
setup do
  clear_standalone!
end
```

## Best practice

Compony has the following convention:

- implement a custom base component in the directory `app/compony/base_components/your_component.rb`
- name the class `BaseComponents::YourComponent` where `BaseComponents` is typically a module simple meant for namespacing

When respecting these conventions, Compony's [generators](/doc/guide/generators.md) will automatically make generated classes inherit from the suitable base component if one is available. In the example above, `rails g component Users::Index` will automatically make the generated class inherit from `BaseComponent::Index`.

[Guide index](/README.md#guide--documentation)