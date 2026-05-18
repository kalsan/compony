- [Back to the guide](/README.md#guide--documentation)
- [List of pre-built components](/doc/guide/pre_built_components.md)

# Pre-built components: List

`Compony::Components::List` is a resourceful component that renders a table/list of
records. It is **not** standalone — it is meant to be nested, typically inside
[`Index`](./index.md) of the same family or [`Show`](./show.md) of an owning family, via
`render_sub_comp(:list, collection)`.

Features: field-inferred or custom columns, per-row intents, pagination, and — when the
[Ransack](https://github.com/activerecord-hackery/ransack) gem is present and at least one
sort/filter is declared — sorting links, a sort select, and a filter/search form.

## Column DSL

| Method | Signature | Description |
| --- | --- | --- |
| `column` | `column(:name, label: nil, class: nil, link_opts: {}) { \|record\| ... }` | Add/define a column. No block → model-field column (auto label, value via `value_for`, only if `:index` permitted). Block is instance-exec'd per row and renders the cell. |
| `columns` | `columns(:a, :b, as_title: false, **kw)` | Bulk `column`. `as_title: true` marks title columns (shown as the card heading in mobile/card layouts). |
| `skip_column` | `skip_column(:name)` | Hide a (possibly inherited) column. |

```ruby
class Components::Orders::List < Compony::Components::List
  setup do
    columns :number, :customer, as_title: true
    columns :total, :created_at
    column :status, class: 'text-end' do |order|
      span order.status.label, class: "badge bg-#{order.status.key}"
    end
  end
end
```

## Filtering & sorting (Ransack)

| Method | Signature | Description |
| --- | --- | --- |
| `filter` | `filter(:name, label: nil) { \|f\| ... }` | Add a filter. No block → field filter or a Ransack predicate string (e.g. `:id_eq`). Block gets the Ransack search form and renders label + input. |
| `filters` | `filters(:a, :b, **kw)` | Bulk `filter`. |
| `sort` | `sort(:name, label: nil)` | Add a sort criterion (must be Ransack-sortable). Generates one sort link + asc/desc entries. |
| `sorts` | `sorts(:a, :b)` | Bulk `sort`. |
| `default_sorting` | `default_sorting('id desc')` | Default Ransack sort applied when none chosen. |

```ruby
setup do
  filters :number, :status
  filter :overdue, label: 'Overdue' do |f|
    concat f.check_box(:overdue_eq, {}, true, false)
  end
  sorts :number, :created_at
  default_sorting 'created_at desc'
end
```

## Per-row intents

`row_intents` opens the [intent management DSL](/doc/guide/intents.md#exposed-intents)
(`add`/`remove`, `before:`) applied to each row's record:

```ruby
setup do
  row_intents do
    remove :destroy
    add :archive, ->(record) { record }, method: :patch, before: :edit
  end
end
```

## Toggles, paging, styling

All have matching constructor kwargs so a nesting parent can override per render
(`render_sub_comp(:list, coll, skip_pagination: true, skip_columns: [:order])`).

| DSL | Default | Purpose |
| --- | --- | --- |
| `pagination(bool)` | on | Enable/disable paging (off loads all rows). |
| `results_per_page(n)` | 20 | Rows per page. |
| `filtering(bool)` | on | Enable/disable the filter form. |
| `sorting(bool)` / `sorting_in_filter(bool)` / `sorting_links(bool)` | on | Toggle sort UIs. |
| `filter_label_class` / `filter_input_class` / `filter_select_class` / `filter_item_wrapper_class` | — | CSS classes for filter form elements. |

Constructor `skip_*` kwargs: `skip_pagination`, `skip_filtering`, `skip_sorting`,
`skip_sorting_in_filter`, `skip_sorting_links`, `skip_columns:`, `skip_row_intents:`,
`skip_filters:`, `results_per_page:`, `default_sorting:`.

## Customizing rendering

`List` exposes named `content` blocks (`:data`, `:filter`, `:pagination`, `:sorting_links`,
…) that you override — almost always once, in an app `BaseComponents::List`, to fit your UI
framework, then inherited everywhere:

```ruby
module BaseComponents
  class List < Compony::Components::List
    setup do
      filter_input_class 'form-control'
      content :filter, hidden: true do
        # Bootstrap-styled filter form wrapper
      end
      content :data, hidden: true do
        # Bootstrap table / responsive cards
      end
    end
  end
end
```

Embedding a child list inside a Show, dropping the FK column and preserving the active tab
across filter submits:

```ruby
concat render_sub_comp(:list, @data.line_items,
                       skip_columns: [:order],
                       params_in_filter: [param_name('tab')])
```

See [Real-world patterns](../patterns.md#4-list-customization) for the recurring app setup.