- [Back to the guide](/README.md#guide--documentation)
- [List of pre-built components](/doc/guide/pre_built_components.md)

# Pre-built components: Show

`Compony::Components::Show` is a resourceful standalone component corresponding to a Rails
`show` action. It loads `@data` by `:id` and presents its fields.

## What it does by default

From `lib/compony/components/show.rb`:

- **Route:** `standalone path: "/#{family_name}/:id"` with an `:id` constraint that accepts
  integer **or** UUID ids, `verb :get` authorized by `can?(:show, @data)`.
- **Labels:** long = `data.label`; short = a generic translated "Show".
- **Exposed intents:** `:edit` and `:destroy` for `@data`, plus a `:back_to_owner` intent
  if the model is [owned](/doc/guide/ownership.md).
- **Content blocks:**
  - `:label` → `h2 component.label`
  - `:main` → renders the `:data` block (override `:main` to wrap `:data` in a card etc.)
  - `:data` (hidden) → if no columns were declared, calls `all_field_columns(@data)`, then
    renders a two-column table of label/value per permitted field.

```ruby
class Components::Users::Show < Compony::Components::Show; end   # fully functional
```

## Column DSL

`Show` shares a `column`/`columns` DSL with [`List`](./list.md) (here "column" means an
attribute row, since Show renders one record).

| Method | Signature | Description |
| --- | --- | --- |
| `column` | `column(:name, label: nil, class: nil, link_opts: {}, link_to_component: :show) { \|record\| ... }` | Add/define one attribute row. Without a block, treated as a model field; the block (instance-exec'd per record) supplies the value. |
| `columns` | `columns(:a, :b, **shared_kwargs)` | Bulk `column`. |
| `all_field_columns` | `all_field_columns(@data)` | Add a column for every model field (the default when none declared). |
| `skip_column` | `skip_column(:name)` | Drop an inherited column. When nesting Show in a parent, prefer the constructor's `skip_columns:` kwarg. |

Field columns are only rendered if the current ability permits `:show` on that attribute;
a `nil` value hides the row.

```ruby
class Components::Users::Show < Compony::Components::Show
  setup do
    columns :name, :email, :created_at
    column :status do |user|                       # custom computed row
      user.active? ? 'Active' : 'Disabled'
    end
    skip_column :created_at                         # if inherited and unwanted

    content do                                      # wrap :data in app chrome
      div class: 'card card-body' do
        content :data
      end
    end
  end
end
```

UUID/string ids work out of the box thanks to the route constraint. For nesting a Show (or
its `:data`) inside another component see [Nesting](/doc/guide/nesting.md); for the app
base-layer approach see [Real-world patterns](../patterns.md#1-the-app-base-component-layer).