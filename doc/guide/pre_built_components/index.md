- [Back to the guide](/README.md#guide--documentation)
- [List of pre-built components](/doc/guide/pre_built_components.md)

# Pre-built components: Index

`Compony::Components::Index` is a resourceful standalone component corresponding to Rails'
`index` controller action. It holds a collection of records and is a thin wrapper that
nests the [`List`](./list.md) component of the same family.

## What it does by default

The shipped `setup` (see `lib/compony/components/index.rb`) is deliberately minimal:

- **Route:** `standalone path: family_name` with a `verb :get` authorized by
  `can?(:index, data_class)`, e.g. `/users`.
- **Label:** `label(:all) { data_class.model_name.human(count: 2) }` — e.g. "Users".
- **Data:** `load_data { @data = data_class.accessible_by(controller.current_ability) }`
  — the full [CanCanCan](https://github.com/CanCanCommunity/cancancan)-scoped collection.
- **Exposed intent:** adds a `:new` intent (unless the model is
  [owned](/doc/guide/ownership.md) by another).
- **Content:** `concat render_sub_comp(:list, @data)` — delegates all rendering to the
  family's `List`.

So with both an `Index` and a `List` component present, a family lists out of the box:

```ruby
class Components::Users::Index < Compony::Components::Index; end
class Components::Users::List  < Compony::Components::List
  setup { columns :name, :email }
end
```

## Typical overrides

Narrow or order the collection:

```ruby
class Components::Users::Index < Compony::Components::Index
  setup do
    load_data { @data = User.accessible_by(current_ability).active.order(:name) }
  end
end
```

Customize the action toolbar via [exposed intents](/doc/guide/intents.md#exposed-intents):

```ruby
setup do
  exposed_intents do
    add :index, :users, label: 'CSV', name: :csv, path: { format: :csv }
    add :import, :users, method: :post, before: :new
  end
end
```

Add a second standalone route serving an alternative `List`:

```ruby
setup do
  standalone path: 'users/archived'
  content :main, hidden: true do
    concat render_sub_comp(:list, @data.archived)
  end
end
```

In practice apps put the layout/markup chrome in a `BaseComponents::Index` and inherit
from that — see [Real-world patterns](../patterns.md#3-index--load_data-scope--nested-list).
For column/filter/sort configuration, see [`List`](./list.md).