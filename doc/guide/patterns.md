[Back to the guide](/README.md#guide--documentation)

# Real-world patterns

Conventions distilled from a range of production Compony apps. These are *idioms*, not
framework requirements — but they recur consistently and are worth adopting. Every example
uses a neutral domain (`Account`, `Order`, `LineItem`, `Document`). Where a pattern relies
on a companion gem (CanCanCan, ActiveType, simple_form, a date/select input) that is
called out.

For exact method signatures see [dsl_reference.md](/doc/guide/dsl_reference.md); for
footguns see [gotchas.md](/doc/guide/gotchas.md).

## 1. The app base-component layer

Almost every non-trivial app inserts one abstract layer between Compony's pre-built
components and the concrete ones. Concrete components inherit from the app layer, never
from Compony directly. This centralizes layout, button styling, and chrome so the whole
app's look changes in one place.

```ruby
# app/components/base_components/show.rb  (a common location; app/compony/ is also used)
module BaseComponents
  class Show < Compony::Components::Show
    setup do
      standalone { layout :backend }     # app-wide Rails layout for all non-publicly accessible components
      button(:icon) { :eye }
      content :main, hidden: true        # concrete comps fill :main…
      content :wrapper do                # …chrome lives here, inherited
        div class: 'card card-body' do
          content :main
        end
      end
    end
  end
end

# app/components/orders/show.rb
class Components::Orders::Show < BaseComponents::Show
end                                      # fully functional, empty body
```

Recurring forms of this layer: `BaseComponents::{Index,Show,New,Edit,Destroy,List}`. The
`content :main, hidden: true` + `content :wrapper` pair is the standard way to let
children override the inner content while inheriting the outer chrome (see
[basic_component.md](/doc/guide/basic_component.md#nesting-content-blocks-calling-a-content-block-from-another)).

Teams sometimes add their own helper DSL on top of this layer (CSV/PDF helpers, archive
toggles, etc.). Keep such helpers in the app base layer, not in concrete components.

## 2. Thin leaf components

Concrete CRUD components are usually empty — all behavior is inherited. Add a `setup` block
only to deviate.

```ruby
class Components::Orders::Destroy < BaseComponents::Destroy; end
class Components::Orders::New     < BaseComponents::New;     end
class Components::Orders::Edit    < BaseComponents::Edit;    end
```

This is the single most common pattern. Prefer it over hand-written endpoints
([gotchas.md #15](/doc/guide/gotchas.md#15-hand-rolled-endpoint-where-a-pre-built-crud-component-exists)).

## 3. Index = `load_data` scope + nested `:list`

Index components rarely render rows themselves; they load a scope and embed the family's
List via `render_sub_comp`.

```ruby
class Components::Orders::Index < BaseComponents::Index
  setup do
    load_data { @data = Order.accessible_by(current_ability).order(created_at: :desc) }
    content do
      h1 Order.model_name.human(count: 2)
      concat render_sub_comp(:list, @data)
    end
  end
end
```

- `accessible_by(current_ability)` is the CanCanCan scoping idiom — pair it with the
  `authorize` block so list and access rules agree.
- `concat` is mandatory around `render_sub_comp`/`render_intent`
  ([gotchas.md #2](/doc/guide/gotchas.md#2-render_intent--render_sub_comp-output-not-appearing)).

## 4. List customization

This pattern is typically combined with a customized `BaseComponents::List` that adds styling and
features to the pre-built list component.

```ruby
class Components::Orders::List < BaseComponents::List
  setup do
    columns :number, :customer, as_title: true   # as_title -> card title on mobile
    columns :total, :created_at
    column :status do |order|                     # computed/custom cell
      span order.status.label, class: "badge bg-#{order.status.key}"
    end
    filters :number, :status
    sorts :number, :created_at
    default_sorting 'created_at desc'
  end
end
```

Embedding a child list inside a Show, dropping the redundant FK column and preserving the
active tab across filter submits:

```ruby
concat render_sub_comp(:list, @data.line_items, skip_columns: [:order],
                                                 params_in_filter: [param_name('tab')])
```

`skip_*` options (`skip_pagination:`, `skip_filtering:`, `skip_columns:`, …) are
constructor kwargs passed through `render_sub_comp`, useful for read-only embeds.

## 5. Custom form + Schemacop, kept in sync

`form_fields` (rendering) and `schema_*` (param whitelist) must mirror each other.

```ruby
class Components::Orders::Form < Compony::Components::Form
  setup do
    form_fields do
      concat field(:number)
      concat field(:customer, as: :tom_select)        # association name, not _id
      concat field(:placed_at, as: :flatpickr_datetime)
      concat pw_field(:access_code)
      concat field(:internal_ref, hidden: true)        # submitted, not shown
      div class: 'row' do                               # arbitrary Dyny layout
        div field(:first_name), class: 'col'
        div field(:last_name),  class: 'col'
      end
    end

    schema_fields :number, :customer, :placed_at, :internal_ref
    schema_pw_field :access_code
  end
end
```

- `as: :tom_select` / `as: :flatpickr_date(time)` are app-registered simple_form inputs
  (TomSelect, Flatpickr) — a good choice for selects and date pickers.
- Use the **association name** in `field`/`schema_field`; `_id` is added automatically
  ([gotchas.md #4](/doc/guide/gotchas.md#4-schema_field-with-the-foreign-key-name)).
- Nested attributes: `f.simple_fields_for(:line_items)` in `form_fields` plus a raw
  `schema_line { ary? :line_items_attributes do ... end }`.
- Multilang fields: `field(:title, multilang: true).each { |i| concat i }` paired with
  `schema_field :title, multilang: true`.

Wire a non-default form into New/Edit with `form_comp_class`:

```ruby
class Components::Orders::QuickAdd < Compony::Components::New
  setup { form_comp_class Components::Orders::QuickAddForm }
end
```

## 6. Autocomplete form (app-level subclass)

Compony does not ship autocomplete, but a very common app pattern is an
`AutocompleteForm` base (subclass of `Compony::Components::Form`) exposing an extra
`standalone` JSON endpoint for an ajax select. Shape:

```ruby
class BaseComponents::AutocompleteForm < Compony::Components::Form
  # class-level `autocomplete(field) { |query, ability| ...collection... }` that
  # registers an extra `standalone :autocomplete_<field>` returning
  # [{ text:, value:, icon: }] JSON, consumed by a TomSelect Stimulus controller.
end

class Components::Orders::Form < BaseComponents::AutocompleteForm
  setup do
    form_fields { concat field(:customer, as: :tom_select) }
    schema_field :customer
    autocomplete(:customer) { |q, ability| Customer.accessible_by(ability).search(q) }
  end
end
```

If you need autocomplete, build this base once and reuse it.

## 7. Tabbed Show via a mixin

Detail pages are split into tabs with a small app mixin that adds a `tab` DSL and renders
a tab bar into `:main`. Each tab body typically renders `content :data` or a nested list.

```ruby
class Components::Orders::Show < BaseComponents::Show
  include ComponentMixins::Tabs

  setup do
    tab(:overview, _('Overview')) { content :data }
    tab(:items,    _('Items'))    { concat render_sub_comp(:list, @data.line_items,
                                                           skip_columns: [:order]) }
  end
end
```

The mixin keys the active tab off a prefixed param (`param_name('tab')`) so multiple
tabbed components can coexist. Compony has no built-in tabs — copy the mixin per app.

## 8. Lifecycle hooks for derived data

- **`after_assign_attributes`** — fill defaults / context after params are assigned,
  before validation: `@data.account_id ||= current_user.account_id`.
- **`before_render`** — verb-independent guards and precomputation. Redirect and the
  content chain is skipped:
  ```ruby
  before_render do
    redirect_to Compony.path(:show, @data) if @data.locked?
  end
  ```
- **`load_data`** — narrow the scope (`accessible_by`, `includes`, ordering).
- **`store_data`** — override persistence (virtual models, file handling, bulk import).
- **`on_{created,updated,destroyed}_redirect_path`** — control where success lands, e.g.
  `Compony.path(:show, @data.parent)` for owned records.

## 9. Exposed intents as the action toolbar

Concrete components tailor the header toolbar by `add`/`remove` on inherited intents.

```ruby
exposed_intents do
  remove :destroy
  add :show, @data, label: 'PDF', name: :pdf, path: { format: :pdf },
      feasibility_action: :pdf
  add :archive, @data, method: :patch, before: :destroy
end
```

- `path: { format: :pdf }` points a button at a format endpoint (see pattern 10).
- `feasibility_action:` ties the button's enabled state to a model `prevent`
  ([feasibility.md](/doc/guide/feasibility.md)).
- State-dependent toolbars (archived vs active) are done by branching inside the
  `exposed_intents` block on `@data`.
- Generating one intent per enum value is common:
  `Period.all.each { |p| add :new, :prices, name: :"new_#{p.key}", path: { price: { period: p.key } } }`.

## 10. CSV / PDF via `respond :format`

A format export is the same component with an extra `respond` branch and an exposed intent
pointing at it. Because overriding `respond` skips the default `authorize`, re-check there
([gotchas.md #3](/doc/guide/gotchas.md#3-overriding-respond-skips-authorization)).

```ruby
standalone path: 'orders' do
  verb :get do
    authorize { can?(:read, Order) }
    respond :csv do
      can?(:read, Order) or raise CanCan::AccessDenied
      send_data(OrderCsv.new(@data).to_csv, filename: 'orders.csv', type: 'text/csv')
    end
    respond :pdf do
      can?(:read, @data) or raise CanCan::AccessDenied
      send_data(OrderPdf.new(@data).render, filename: @data.pdf_name,
                type: 'application/pdf')
    end
  end
end
# exposed_intents { add :index, :orders, label: 'CSV', path: { format: :csv } }
```

## 11. Non-CRUD: job dispatch, toggles, clone

**Job dispatch** — POST-only custom component, enqueue, flash, redirect:

```ruby
class Components::Orders::ScheduleSync < Compony::Component
  setup do
    standalone path: 'orders/schedule_sync' do
      verb :post do
        authorize { can?(:create, Order) }
        respond do
          SyncOrdersJob.perform_later
          flash.notice = _('Queued — give it a few minutes.')
          redirect_to Compony.path(:index, :orders)
        end
      end
    end
    label(:all) { _('Sync now') }
    button(:icon) { :rotate }
  end
end
```

Expose it from Index: `exposed_intents { add :schedule_sync, :orders, method: :post }`.

**State toggle** — inherit `Edit`, flip in `after_assign_attributes`, dynamic label:

```ruby
class Components::Accounts::ToggleActive < Compony::Components::Edit
  setup do
    standalone path: 'accounts/:id/toggle_active' do
      verb :patch do authorize { can?(:toggle_active, @data) } end
    end
    label(:long) { |a| a.active? ? _('Deactivate') : _('Activate') }
    after_assign_attributes { @data.active = !@data.active }
  end
end
```

**Clone** — inherit `New`, load + dup the source in `load_data`, redirect to the copy:

```ruby
class Components::Orders::Clone < Compony::Components::New
  setup do
    standalone path: 'orders/:id/clone'
    load_data do
      source = Order.find(params[:id])
      authorize!(:read, source)          # CanCanCan bang form
      @data = source.dup
    end
    on_created_redirect_path { Compony.path(:show, @data) }
  end
end
```

## 12. Virtual model for non-persistent / upload forms

Inherit `New`, back it with a `Compony::VirtualModel`, take over the response. `@data.save`
is a no-op so business logic goes in `on_created_respond` (or `store_data`).

```ruby
class Components::Documents::Import < Compony::Components::New
  class VirtualModel < Compony::VirtualModel
    attribute :id, :bigint
    belongs_to :account
    has_one_attached :file
    field :account, :association
    field :file,    :attachment
    validates :file, presence: true
  end

  setup do
    standalone path: 'documents/import'
    data_class VirtualModel
    form_comp_class Components::Documents::ImportForm

    # ActiveStorage on a virtual model: validate only, read the tempfile yourself.
    store_data do
      @create_succeeded = @data.validate
      next unless @create_succeeded
      tempfile = params.dig(:documents_virtual_model, :file)&.tempfile
      DocumentImporter.call(account: @data.account, io: tempfile)
    end

    on_created_respond do
      flash.notice = _('Imported.')
      redirect_to Compony.path(:index, :documents)
    end
  end
end
```

See [virtual_models.md](/doc/guide/virtual_models.md) and
[gotchas.md #12](/doc/guide/gotchas.md#12-activestorage-attachment-on-a-virtual-model).

## 13. Public endpoints & webhooks

```ruby
class Components::Public::Webhook < Compony::Component
  setup do
    standalone path: '/webhooks/orders' do
      skip_authentication!
      skip_forgery_protection!
      verb :post do
        authorize { true }                       # still mandatory
        respond do
          expected = "Bearer #{ENV.fetch('WEBHOOK_TOKEN')}"
          got      = request.headers['Authorization'].to_s
          unless ActiveSupport::SecurityUtils.secure_compare(got, expected)
            sleep 1                               # crude timing equalization
            next controller.head(:unauthorized)
          end
          OrderWebhook.process!(request.params)
          controller.head :accepted
        end
      end
    end
  end
end
```

A login-aware redirect splitter is the same shape with `verb :get` + `before_render`
choosing a `Compony.path` by `current_user`.

## 14. Custom button style

Register one app button style and refer to it everywhere via `style:`.

```ruby
class Components::Commons::BootstrapButton < Compony::Components::Buttons::Link
  protected
  def prepare_opts!
    super
    classes = (@comp_opts[:class] || '').split
    classes << 'btn' << "btn-#{@comp_opts[:color] || :primary}"
    @comp_opts[:class] = classes.join(' ')
  end
end
# config/initializers/compony.rb
# Compony.register_button_style :bootstrap, '::Components::Commons::BootstrapButton'
# Compony.default_button_style = :bootstrap
```

Make a separate style per visual kind (dropdown item, pill, compact) and select with
`render_intent(:show, @data, style: :compact)`.

## Good habits

- **CanCanCan everywhere:** `authorize { can?(...) }`, scope with
  `Model.accessible_by(current_ability)`, bang form `authorize!(:read, record)` for
  ad-hoc checks in `load_data`.
- **Always `Compony.path` / `render_intent`,** never hardcoded routes or `button_to`
  ([gotchas.md #11](/doc/guide/gotchas.md#11-redirect_to-with-a-hardcoded-path), [#15](/doc/guide/gotchas.md#15-hand-rolled-endpoint-where-a-pre-built-crud-component-exists)).
- **Place a resourceful component in the family of the model it acts on,** not the family
  it is reached from; pass parent context via path params.
- **Keep virtual/form-only fields off models** — use ActiveType/VirtualModel
  ([gotchas.md #16](/doc/guide/gotchas.md#16-attr_accessor-on-a-model-for-form-only-fields)).
- **`concat`** around every `render_intent`/`render_sub_comp`/`field` in a block.

[Guide index](/README.md#guide--documentation)
