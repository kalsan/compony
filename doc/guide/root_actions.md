[Back to the guide](/README.md#guide)

# Compony root actions

The word "actions" is heavily overused, so here is a disambiguation:

- Rails controller actions: a method that is implemented in a Rails controller
- CanCanCan actions: the first method to CanCanCan's `can?` method
- Compony root actions: buttons that point to other components

At this point, Compony actions are a loose concept, which will likely be refined in the future. Currently, Compony actions are defined as buttons, rendered by the application layout, that point to other components. They provide context-sensitive buttons to your application.

## Defining and manipulating root actions

In addition to regular buttons that are rendered as part of the content blocks, components can expose root actions with the `actions` call. Root actions will only be rendered if the component they are defined in is currently the root component.

To have a component expose a root action, call the method `action` in a `setup` block and return a Compony button:

```ruby
setup do
  action :edit do
    Compony.button(:edit, @data)
  end

  action :destroy do
    Compony.button(:destroy, @data)
  end
end
```

The name of the action ("edit" and "destroy" in the example above) allows you to refer to that action in a component inheriting from this one:

```ruby
# Assuming that this component inherits from the example above
setup do
  skip_action :destroy

  action :overview, before: :edit do
    Compony.button(:index, :users, label: 'Overview')
  end
end
```

In this example, two actions will be shown: overview and edit.

An action button can be disabled through the [feasibility framework](./feasibility.md). However, it can also instead be hidden completely by returning nil from within the action block:

```ruby
action :edit do
  next if @data.locked?
  Compony.button(:edit, @data)
end
```

The action in this example will be skipped entirely if `locked?` returns true.

## Displaying root actions

Root actions are not shown by default in Compony because layouting is up to you. In order to display the root component's actions, add the following view helper call to your layout:

```erb
<%# layouts/application.html.erb %>
...
<%= compony_actions %>
```

If there is currently no root component, or if the root component defines no actions, this does nothing. However, if there are root actions available, the Compony buttons returned by the root component will be rendered.