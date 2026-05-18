[Back to the guide](/README.md#guide--documentation)

# Advanced example

[example.md](/doc/guide/example.md) shows the basics. This one combines patterns you hit in
real apps: a custom form, feasibility, exposed intents, a CSV export endpoint, a
`before_render` guard, and a virtual-model launch form for a background job.

Domain: invoicing. An `Invoice` has line items, can be locked, exported as CSV, and a
background "send reminders" job can be launched from a non-persistent form.

## The models

```ruby
# app/models/invoice.rb
class Invoice < ApplicationRecord
  has_many :line_items, dependent: :destroy
  accepts_nested_attributes_for :line_items, allow_destroy: true
  belongs_to :customer

  field :number,   :string
  field :customer, :association
  field :total,    :decimal
  field :locked,   :boolean
  field :issued_at, :datetime

  def label = number

  # Feasibility: a locked invoice must not be edited or destroyed.
  # Back every important prevention with a real validation (see note in feasibility.md).
  prevent %i[edit destroy], 'the invoice is locked' do
    locked?
  end
  validate { errors.add(:base, 'invoice is locked') if locked_was && locked? }
end

# app/models/line_item.rb
class LineItem < ApplicationRecord
  belongs_to :invoice
  field :description, :string
  field :amount,      :decimal
  def label = description
end
```

## Index with a CSV export endpoint and exposed intents

One component, two routes: the HTML list and a `.csv` download. The CSV intent is exposed
so the layout renders a "Download CSV" button in the page header.

```ruby
class Components::Invoices::Index < Compony::Component
  include Compony::ComponentMixins::Resourceful

  setup do
    label(:all) { 'Invoices' }

    standalone path: 'invoices' do
      verb :get do
        authorize { can?(:read, Invoice) }
        # Default (HTML) response renders content. CSV gets its own response:
        respond :csv do
          authorize_csv = can?(:read, Invoice) or raise CanCan::AccessDenied # respond skips authorize!
          send_data(InvoiceCsv.new(@data).to_csv, filename: 'invoices.csv', type: 'text/csv')
        end
      end
    end

    load_data { @data = Invoice.accessible_by(current_ability).order(issued_at: :desc) }

    exposed_intents do
      add :index, :invoices, label: 'Download CSV', name: :csv, path: { format: :csv }
      add :request_reminders, :invoices, label: 'Send reminders', method: :get
    end

    content do
      concat render_intent(:new, :invoices, button: { label: { format: :short } })
      concat render_sub_comp(:list, @data)
    end
  end
end
```

Notes:

- `respond :csv` handles `GET /invoices.csv`. Because overriding `respond` **skips the
  default `authorize`** (see [gotchas.md](/doc/guide/gotchas.md#3-overriding-respond-skips-authorization)),
  the CSV branch re-checks the ability itself.
- `path: { format: :csv }` on the exposed intent makes its button point at `.csv`.
- The layout renders exposed intents of `Compony.root_comp` — see
  [intents.md](/doc/guide/intents.md#rendering-exposed-intents).

## A custom Form with nested line items

`Edit`/`New` look for `Components::Invoices::Form` by default. We write it with
`accepts_nested_attributes_for` via `simple_form`'s `simple_fields_for`, and whitelist the
nested params with a raw `schema_line`.

```ruby
class Components::Invoices::Form < Compony::Components::Form
  setup do
    form_fields do
      concat field(:number)
      concat field(:customer, as: :tom_select) # association name, NOT customer_id
      concat field(:issued_at, as: :flatpickr_datetime)
      concat(f.simple_fields_for(:line_items) do |lf|
        concat lf.input(:description)
        concat lf.input(:amount)
      end)
    end

    schema_fields :number, :customer, :issued_at
    # Nested attributes need a manual Schemacop line:
    schema_line do
      ary? :line_items_attributes do
        list :hash do
          int? :id
          str? :description
          num? :amount
          boo? :_destroy
        end
      end
    end
  end
end
```

`schema_field :customer` (association name) lets Compony add `customer_id` automatically —
passing `:customer_id` here would not work
([gotchas.md](/doc/guide/gotchas.md#4-schema_field-with-the-foreign-key-name)).

## Edit: thin, plus a guard and a custom redirect

`Edit` inherits all CRUD wiring. We only add a `before_render` guard (independent of HTTP
verb) and override where a successful save lands.

```ruby
class Components::Invoices::Edit < Compony::Components::Edit
  setup do
    before_render do
      if @data.locked?
        flash.alert = 'This invoice is locked.'
        redirect_to Compony.path(:show, @data)
      end
    end

    on_updated_redirect_path { Compony.path(:show, @data) }
  end
end
```

The `prevent :edit` in the model already greys out the edit button with a tooltip; the
`before_render` guard plus the model validation stop a hand-crafted request
([feasibility.md](/doc/guide/feasibility.md) explains why all three layers are needed).

`Components::Invoices::New`, `Show`, `Destroy` can stay empty — the pre-built parents do
the work.

## A virtual-model launch form for a background job

"Send reminders" should pop a small form (which customers? how many days overdue?) and, on
submit, queue a job — nothing is persisted. Inherit `New`, back it with a
`Compony::VirtualModel`, and take over `on_created_respond`.

```ruby
class Components::Invoices::RequestReminders < Compony::Components::New
  class VirtualModel < Compony::VirtualModel
    attribute :min_days_overdue, :integer, default: 7
    attribute :only_locked,      :boolean, default: false
    field :min_days_overdue, :integer
    field :only_locked,      :boolean
    validates :min_days_overdue, numericality: { greater_than: 0 }
    def label = 'Reminder request'
  end

  class Form < Compony::Components::Form
    setup do
      form_fields do
        concat field(:min_days_overdue)
        concat field(:only_locked)
      end
      schema_fields :min_days_overdue, :only_locked
    end
  end

  setup do
    standalone path: 'invoices/request_reminders' # avoid clashing with the New route
    data_class VirtualModel
    form_comp_class Components::Invoices::RequestReminders::Form
    label(:all) { 'Send reminders' }

    # @data.save is a no-op (virtual). on_created_respond fires only after validations pass.
    on_created_respond do
      SendRemindersJob.perform_later(min_days_overdue: @data.min_days_overdue,
                                     only_locked:      @data.only_locked)
      flash.notice = 'Reminders queued — give it a few minutes.'
      redirect_to Compony.path(:index, :invoices)
    end
  end
end
```

Why it works: inheriting `New` gives the `new`/`create` flow. On submit Compony validates,
re-renders the form with errors on failure, otherwise calls `@data.save` (a no-op on a
virtual model) and runs `on_created_respond`, where you regain control. For ActiveStorage
on a virtual model, also override `store_data` to only `validate` — see
[virtual_models.md](/doc/guide/virtual_models.md).

[Guide index](/README.md#guide--documentation)
