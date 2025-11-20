[Back to the guide](/README.md#guide)

# Standalone (routing to components)

As stated earlier, Compony can generate routes to your components. This is achieved by using the standalone DSL inside the setup block. The first step is calling the method `standalone` with a path. Inside this block, you will then specify which HTTP verbs (e.g. GET, PATCH etc.) the component should listen to. As soon as both are specified, Compony will generate an appropriate route.

Assume that you want to create a simple component `statics/welcome.rb` that displays a static welcome page. The component should be exposed under the route `'/welcome'` and respond to the GET method. Here is the complete code for making this happen:

```ruby
# app/components/statics/welcome.rb
class Components::Statics::Welcome < Compony::Component
  setup do
    label(:all) { 'Welcome' }

    standalone path: 'welcome' do
      verb :get do
        authorize { true }
      end
    end

    content do
      h1 'Welcome to my dummy site!'
    end
  end
end
```

This is the minimal required code for standalone. For security, every verb config must provide an `authorize` block that specifies who has access to this standalone verb. The block is given the request context and is expected to return either true (access ok) or false (causing the request to fail with `Cancan::AccessDenied`).

Typically, you would use this block to check authorization using the CanCanCan gem, such as `authorize { can?(:read, :welcome) }`. However, since we skip authentication in this simple example, we pass `true` to allow all access.

The standalone DSL has more features than those presented in the minimal example above. Excluding [resourceful](./resourceful.md) features, the full list is:

- `standalone` can be called multiple times, for components that need to expose multiple paths, as described below. Inside each `standalone` call, you can call:
  - `skip_authentication!` which disables authentication, in case you provided some. You need to implement `authorize` regardless.
  - `skip_forgery_protection!` which disables CSRF protection for the controller action generated for this standalone configuration.
  - `layout` which takes the file name of a Rails layout and defaults to `layouts/application`. Use this to have your Rails application look differently depending on the component.
  - `verb` which takes an HTTP verb as a symbol, one of: `%i[get head post put delete connect options trace patch]`. `verb` can be called up to once per verb. Inside each `verb` call, you can call (in the non-resourceful case):
    - `authorize` is mandatory and explained above.
    - `respond` can be used to implement special behavior that in plain Rails would be placed in a controller action. The default, which calls `before_render` and the `content` blocks, is usually the right choice, so you will rarely implement `respond` on your own. See below how `respond` can be used to handle different formats or redirecting clients. **Caution:** `authorize` is evaluated in the default implementation of `respond`, so when you override that block, you must perform authorization yourself!

## Exposing multiple paths in the same component (calling standalone multiple times)

If your component loads data dynamically from a JavaScript front-end (e.g. implemented via Stimulus), you will find yourself in the situation where you need an extra route for a functionality that inherently belongs to the same component. Example use cases would be search fields that load data as the user types, maps that load tiles, dynamic photo galleries etc.

In this case, you can call `standalone` a second time and provide a name for your extra route:

```ruby
setup do
  # Regular route for rendering the content
  standalone path: 'map/viewer' do
    verb :get do
      authorize { true }
    end
  end

  # Extra route for loading tiles via AJAX
  standalone :tiles, path: 'map/viewer/tiles' do
    verb :get do
      respond do # Again: overriding `respond` skips authorization! This is why we don't need to provide an `authorize` block here.
        controller.render(json: MapTiler.load(params, current_ability)) # current_ability is provided by CanCanCan and made available by Compony.
      end
    end
  end

  # More code for labelling, content etc.
end
```

Please note that the idea here is to package things that belong together, not to provide different kinds of content in a single component. For displaying different pages, use multiple components and have each expose a single route.

## Naming of exposed routes

The routes to standalone components are named and you can point to them using Rails' `..._path` and `..._url` helpers. The naming scheme is: `[standalone]_[component]_[family]_comp`. Examples:

- Default standalone: `Components::Users::Index` exports `index_users_comp` and thus `index_users_comp_path` can be used.
- Named standalone: If `standalone :foo, path: ...` is used within `Components::Users::Index`, the exported name is `foo_index_users_comp`.

## Handling formats

Compony is capable of responding to formats like Rails does. This is useful to deliver PDFs, CSV files etc. to a user from within Compony. This can be achieved by specifying the `respond` block:

```ruby
setup do
  standalone path: 'generate/report' do
    verb :get do
      # Respond with a file when generate/report.pdf is GETed:
      respond :pdf do
        file, filename = PdfGenerator.generate(params, current_ability)
        send_data(file, filename:, type: 'application/pdf')
      end
      # If someone visits generate/report, issue a 404:
      respond do
        fail ActionController::RoutingError, 'Unsupported format - please make sure your URL ends with `.pdf`.'
      end
    end
  end
end
```

## Redirect in `respond` or in `before_render`?

Rails controller redirects can be issued both in a verb DSL's `respond` block and in `before_render`. The rule of thumb that tells you which way to go is:

- If you want to redirect depending on the HTTP verb, use `respond`.
- If you want to redirect depending on params, state, time etc.  **independently of the HTTP verb**, use `before_render`, as this is more convenient than writing a standalone -> verb -> respond tree.

## Path constraints

When calling `standalone`, you may specify the keyword `constraints` that will be passed to the route. For example:

```ruby
# In your component
standelone path: '/:lang', constraints: { lang: /([a-z]{2})?/i }

# This will automatically lead to a route of this form:
get ':lang', constraints: { lang: /([a-z]{2})?/i }
```

## Passing scopes

When calling `standalone`, you may specify the keyword `scope` to wrap the component's Rails route into a route scope. Additionally, you may specify a hash `scope_args`, which will be passed as keyword arguments to the `scope` call in the route:

```ruby
# In your component
standalone path: '/welcome', scope: '(:lang)', scope_args: { lang: /([a-z]{2})?/i } do
  verb :get do
    # ....
  end
end

# This will automatically lead to a route of this form:
scope '(:lang)', lang: /([a-z]{2})?/i do
  get 'welcome', to: 'compony#your_component'
end
```