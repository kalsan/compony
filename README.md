TODO: Write this

Notes:

- `model` is an ApplicationModel or similar (e.g. ActiveType, but not guarantted to work at this point), `.model_name` is important
- `data` can be model or models
- To redirect instead of rendering, use `before_render` if the redirect is conditional (e.g. if validation passes), or `respond` if always redirecting.
  - As a rule of thumb, use `before_render` if there is a `content` block (even by inheritance) and `respond` otherwise.