TODO: Write this

Notes:

- `model` is an ApplicationModel or similar (e.g. ActiveType, but not guarantted to work at this point), `.model_name` is important
- `data` can be model or models
- To redirect instead of rendering, use `before_render` if the redirect is conditional (e.g. if validation passes), or `respond` if always redirecting.
  - As a rule of thumb, use `before_render` if there is a `content` block (even by inheritance) and `respond` otherwise.
- To protect a custom controller by compony authentication, use in the controller: `before_action Compony.authentication_before_action`

Feature sets:

- Base feature: Components
  - replace routes, views and controllers
  - actions
  - params and nesting
  - skipping authentication
  - lifecycle
    - standalone
    - resourcefulness
    - authorization
- Buttons and links
  - labelling
  - coloring
- Fields and field groups
- Feasibility
- Premade components
  - button
  - destroy
  - form
  - with_form
  - new
  - edit