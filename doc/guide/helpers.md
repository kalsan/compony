[Back to the guide](/README.md#guide)

# Compony helpers, links and buttons

When pointing to or instantiating a component, writing the whole class name would be cumbersome. For this reason, Compony has several helpers that will retrieve the correct class for you. The most important ones are explained in this subsection. The terms are defined as follows:

- Component name or constant: For a component `Components::Users::Show`, this would be `'Show'`, `'show'`, or `:show`
- Family name or constant: For a component `Components::Users::Show`, this would be `'Users'`, `'users'`, or `:users`
- Model: an instance of a class that implements the `model_name` method in the same way as `ActiveRecord::Base` does. For helpers that support giving models, Compony will use `model_name` to auto-infer the family name. This requires you to name the component according to convention, i.e. the family name must match the model's pluralized camelized `model_name`.

## Getting the class of a component

- `Compony.comp_class_for(comp_name_or_cst, model_or_family_name_or_cst)` returns the class or nil if not found.
- `Compony.comp_class_for!(comp_name_or_cst, model_or_family_name_or_cst)` returns the class. If the class is not found, an error will be raised.

Example:

```ruby
my_component = Compony.comp_class_for!(:show, User.first).new
my_component.class # Components::Users::Show
```

### Getting a path to a component

- `Compony.path(comp_name_or_cst, model_or_family_name_or_cst)` returns the route to a component. Additional positional and keyword arguments will be passed to the Rails helper.

If a model is given, its ID will automatically be added as the `id` parameter when generating the route. This means:

- To generate a path to a non-resourceful component, pass the family name.
- To generate a path to a resourceful component, prefer passing an instance instead of a family name.

Examples:

```ruby
link_to 'User overview', Compony.path(:index, :users) # -> 'users/index'
link_to 'See user page', Compony.path(:show, User.first) # -> 'users/show/1'
link_to 'See user page', Compony.path(:show, :users, id: 1) # -> 'users/show/1'
```

Note that the generated paths in the example are just for illustration purposes. The paths point to whatever path you configure in the target component's default standalone config. Also, this example is not how you should generate links to components, as is explained in the next subsection.

### Customizing path generation

By implementing `path do ... end` inside the `setup` method of a component, you can override the way paths to that component are generated. Customizing the path generation will affect all mentioned methods mentioned here involving paths, such as `Compony.path`, `compony_link`, `Compony.button`, `compony_button` etc.

This is an advanced usage. Refer to the default implementation of `Component`'s `path_block` to see an exmple.

## Generating a link to a component

In order to allow a user to visit another component, don't implement your links and buttons manually. Instead, use Compony's links and buttons, as those extract information from the target component, avoiding redundant code and making refactoring much easier.

Compony comes with the view helper `compony_link` that is available in any of your views, including a component's `content` blocks. The link's label is inferred from the component the link points to. `compony_link` is used as follows:

- To generate a link to a non-resourceful component, pass the family name.
- To generate a link to a resourceful component, prefer passing an instance instead of a family name. More precisely, you must pass an instance if the component's label requires an argument.

Any additional arguments passed to `compony_link` will be given to Rails' `link_to` method, allowing you to set parameters, HTTP method, terget, rel etc.

Examples:

```ruby
compony_link(:index, :users) # "View all users" -> 'users/index'
compony_link(Components::Users::Index) # same as above
compony_link(:index, :users, label_opts: { format: :short }) # "All" -> 'users/index'
compony_link(:show, User.first) # "View John Doe" -> 'users/show/1'
compony_link(:destroy, User.first, method: :delete) # "Delete John Doe" -> 'users/destroy/1'

# NOT working:
compony_link(:show, :users, id: 1) # Error: The label for the Users::Show component takes an argument which was not provided (the user's label)
```

## Generating a button to a component

Compony buttons are components that render a button to another component. While the view helper `compony_button` works similar to `compony_link`, you can also manually instantiate a button and work with it like with any other component.

Similar to links, Compony buttons take a component name and either a family or model. The label, path, method and title (i.e. tooltip) can be overwritten by passing the respective arguments as shown below.

Compony buttons have a type that is either `:button` or `:submit`. While the first works like a link redirecting the user elsewhere, the second is used for submitting forms. It can be used inside a `form_for` or `simple_form_for`.

A compony button figures out on it's own whether it's clickable or not:

- Buttons can be disabled explicitly by passing `enabled: false` as a parameter.
- If a user is not authorized to access the component a button is pointing to, the button is not displayed.
- If the target component should not be accessible due to a prevention in the [feasibility framework](./feasibility.md), the button is disabled and a tooltip is shown explaining why the button is not clickable.

Do not directly instantiate `Compony::Components::Button`. Instead, use `Compony.button`:

```ruby
my_button = Compony.button(:index, :users) # "View all users" -> 'users/index'
my_button = Compony.button(:index, :users, label_opts: { format: :short }) # "All" -> 'users/index'
my_button = Compony.button(:index, :users, label: 'Back') # "Back" -> 'users/index'
my_button = Compony.button(:show, User.first) # "View John Doe" -> 'users/show/1'
my_button = Compony.button(:new, :users, label: 'New customer', params: { user: { type: 'customer' } }) # "New customer" -> 'users/new?user[type]=customer'
my_button = Compony.button(:new, :users, label: 'New customer', params: { user: { type: 'customer' } }, method: :post) # Instantly creates user.
my_button = Compony.button(label: 'I point to a plain Rails route', path: 'some/path') # Specifying a custom path
my_button = Compony.button(label: 'Nothing happens if you click me') # javascript:void()
my_button = Compony.button(label: 'Not implemented yet', enabled: false) # Disabled button

# `enabled` and `path` can also be provided with a callable (block or lambda) to defer evaluation until when the button is rendered.
# The lambdas will be called in the button's `before_render` and given the controller, allowing you to query request specific data.
my_button = Compony.button(label: 'I point to a plain Rails route', path: ->{ |controller| controller.helpers.some_rails_path })
my_button = Compony.button(:index, :users, enabled: -> { |controller| controller.current_ability.can?(:read, :index_pages) })
```

A Compony button can be rendered like any other component:

```erb
<%= my_button.render(controller) %>
```

However, it is much easier to just use the appropriate view helper instead, which takes the same arguments as `Compony.button`:

```ruby
compony_button(:index, :users)
```

If you need to render many buttons that share a parameter, the call `Compony.with_button_defaults` allows you to DRY up your code:

```ruby
# Assuming this is inside a Dyny view context and each button should be inside a div.
# Without with_button_defaults:
  div compony_button(:new, :documents, label_opts: { format: :short }, method: :post)
  div compony_button(:new, :letters, label_opts: { format: :short }, method: :post)
  div compony_button(:new, :articles, label_opts: { format: :short }, method: :post)

# Equivalent using with_button_defaults:
Compony.with_button_defaults(label_opts: { format: :short }, method: :post) do
  div compony_button(:new, :documents)
  div compony_button(:new, :letters)
  div compony_button(:new, :articles)
end
```

### Implementing custom buttons

Plain HTML buttons are not exactly eye candy, so you will likely want to implement your button kind with black jack and icons. For this reason, the button instantiated by Compony's button helpers can be customized.

To build your own button class, inherit as follows:

```ruby
class MyButton < Compony::Components::Button
  def initialize(*args, **kwargs, &block) # Add extra arguments here
    super(*args, **kwargs, &block)
    # Add extra initialization code here
  end

  # Add/replace before_render/content here. Be careful to not overwrite code you depend on. Check Compony's button's code for details.
end
```

Then, in the Compony initializer, register your custom button class to have Compony instantiate it whenever `Compony.button` or another helper is called:

```ruby
# config/initializers/compony.rb
Compony.button_component_class = 'MyButton'
```