# Compony test suite

Run with `bundle exec rspec` (or `rake spec`).

## Layout

- `spec/dummy` — a minimal Rails app (in-memory SQLite) hosting the gem, with a `User`
  model, CRUD components under `app/components/users`, and plain components under
  `app/components/statics`. The schema lives in `spec/dummy/db/schema.rb` and is loaded
  fresh on boot by `spec/rails_helper.rb`.
- `spec/compony` — unit specs for the plain-Ruby parts (module API, intents, model mixin,
  model fields, `MethodAccessibleHash`, `NaturalOrdering`, component DSL basics).
- `spec/requests` — request specs exercising routing, rendering, the pre-built CRUD
  components (Index/Show/New/Edit/Destroy/Form), feasibility and authorization end-to-end.

## Version pins (Gemfile)

- `rack >= 3.1`: the pre-built components respond with the `:unprocessable_content`
  status, which only exists from Rack 3.1.
- `rails ~> 7.2.1`: Rails 8.1 renamed the form helper `text_area` to `textarea`, which
  collides with Dyny 0.0.3's `textarea` HTML tag helper on the view context and breaks
  every simple_form textarea. Remove the pin once Dyny is fixed for Rails >= 8.1.
