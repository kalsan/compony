[Back to the guide](/README.md#guide--documentation)

# What is a component?

Compony components are nestable elements that are capable of replacing Rails' routes, views and controllers. They structure code for data manipulation, authentication and rendering into a single class that can easily be subclassed. This is achieved with Compony's DSL that provides a readable and overridable way to store your logic.

Just like Rails, Compony is opinionated and you are advised to structure your code according to the examples and explanations. This makes it easier for others to dive into existing code.

# A basic (bare) component

## Naming

Compony components must be named according to the pattern `Components::FamilyName::ComponentName`.

- The family name should be pluralized and is analog to naming a Rails controller. For instance, when you would create a `UsersController` in plain Rails, the Compony family equivalent is `Users`.
- The component name is the Compony analog to a Rails action.

Example: If your plain Rails `UsersController` has an action `show`, the equivalent Compony component is `Components::Users::Show` and is located under `app/components/users/show.rb`.

If you have abstract components (i.e. components that your app never uses directly, but which you inherit from), you may name and place them arbitrarily.

## Initialization, manual instantiation and rendering

You will rarely have to override `def initialize` of a component, as most of your code will go into the component's `setup` block as explained below. However, when you do, make sure to forward all default arguments to the parent class, as they are essential to the component's function:

```ruby
def initialize(some_positional_argument, another=nil, *args, some_keyword_argument:, yetanother: 42, **kwargs, &block)
  super(*args, **kwargs, &block) # Typically you should call this first
  @foo = some_positional_argument
  @bar = another
  @baz = some_keyword_argument
  @stuff = yetanother
end
```

Typically, your components will be instantiated and rendered by Compony through the ["standalone" feature](./standalone.md). Nonetheless, it is possible to do so manually as well, for instance if you'd like to render a component from within an existing view in your application:

```erb
<% index_users_comp = Components::Users::Index.new %>
<%= index_users_comp.render(controller) %>
```

Note that rendering a component always requires the controller as an argument. It also possible to pass an argument `locals` that will be made available to `render` (see below):

```erb
<% index_users_comp = Components::Users::Index.new %>
<%= index_users_comp.render(controller, locals: { weather: :sunny }) %>
```

## Setup

Every component must call the static method `setup` which will contain most of the code of your components. This can be achieved either by a call directly from your class, or by [inheriting](/doc/guide/inheritance.md) from a component that calls `setup`. If both classes call the method, the inherited class' `setup` is run first and the inheriting's second, thus, the child class can override setup properties of the parent class.

Call setup as follows:

```ruby
class Components::Users::Show < Compony::Component
  setup do
    # Your setup code goes here
  end
end
```

The code in setup is run at the end the component's initialization. In this block, you will call a number of methods that define the component's behavior and which we will explain now.

### Labelling

This defines a component's label, both as seen from within the component and from the outside, e.g. from an [intent](/doc/guide/intents.md). You can query the label in order to display it as a title in your component. Links and buttons to components will also display the same label, allowing you to easily rename a component, including any parts of your UI that point to it.

Labels come in different formats, short and long, with long being the default. Define them as follows if your component is about a specific object, for instance a show component for a specific user:

```ruby
setup do
  label(:short) { |user| user.label } # Assuming your User model has a method or attribute `label`.
  label(:long) { |user| "Displaying user #{user.label}" } # In practice, you'd probably use I18n.t or FastGettext here to deal with translations.

  # Or use this short hand to set both long and short label to the user's label:
  label(:all) { |user| user.label }
end
```

To read the label, from within the component or from outside, proceed as follows:

```ruby
label(User.first) # This returns the long version: "Displaying user John Doe".
label(User.first, format: :short) # This returns the short version "John Doe".
```

It is important to note that since your label block takes an argument, you must provide the argument when reading the label. Only up to one argument is supported. Typically, label blocks of all [resourceful components](/doc/guide/resourceful.md) take 1 argument while all others take 0.

Here is an example on how labelling looks like for a component that is not about a specific object, such as an index component for users:

```ruby
setup do
  label(:long) { 'List of users' }
  label(:short) { 'List' }
end
```

And to read those:

```ruby
label # "List of users"
label(format: :short) # "List"
```

If you do not define any labels, Compony will fallback to the default which is using Rail's `humanize` method to build a name from the family and component name, e.g. "index users".

Additionally, components can specify an icon and a color. These are not used by Compony directly and it is up to you to to define how and where to use them. Example:

```ruby
setup do
  color { '#AA0000' }
  icon { %i[fa-solid circle] }
end
```

To retrieve them from outside the component, use:

```ruby
my_component.color # '#AA0000'
my_component.icon # [:'fa-solid', :circle]
```

### Providing content

Basic components do not come with default content. Instead, you must call the method `content` inside the setup block and provide a block containing your view. It will be evaluated inside a [request context](/doc/guide/internal_datastructures.md#requestcontext).

In this block, provide the HTML to be generated using Dyny: [https://github.com/kalsan/dyny](https://github.com/kalsan/dyny)

Here is an example of a component that renders a title along with a paragraph:

```ruby
setup do
  label(:all) { 'Welcome' }
  content do
    h1 'Welcome to my basic component.'
    para "It's not much, but it's honest work."
  end
end
```

#### Naming content blocks, ordering and overriding them in subclasses

Content blocks are actually named. The `content` call adds or replaces a previously defined content block, e.g. in an earlier call to `setup` in a component's superclass. When calling `content` without a name, it defaults to `main` and will overwrite any previous `main` content. However, you can provide your own name and refer to other names by using the `before:` keyword.

```ruby
setup do
  content do # will become :main
    h1 'Welcome to my basic component.'
  end
  content :thanks do
    para 'Thank you and see you tomorrow.'
  end
  content :middle, before: :thanks do
    para 'This paragraph is inserted between the others.'
  end
  content :thanks do
    para 'Thank you and see you tonight.' # this overwrites "Thank you and see you tomorrow."
  end
  content :first, before: :main do
    para 'This appears first.'
  end
end
```

This results in:
  - This appears first.
  - Welcome to my basic component.
  - This paragraph is inserted between the others.
  - Thank you and see you tonight.

As you see, overusing this feature can lead to messy code as it becomes unclear what happens in what order. For this reason, this feature should only be used to decouple the content of your abstract components for allowing surgical overrides in [subclasses](/doc/guide/inheritance.md).

It is a good convention to always have one content block named `:main`, as you might want to refer to it in subclasses.

#### Nesting content blocks, calling a content block from another

In some situations, such as in forms, it can be useful to nest content blocks. This will also allow subclasses to override a wrapper while keeping the content, and vice versa. To make this possible, you can also use the `content` keyword inside a content block. Note that unlike the call in `setup`, this call will render a content block instead of defining it. This happens inside the request context and the content block must be defined inside the current component.

Note that you cannot call another component's content block this way.

Here is an example on how to use this feature, e.g. to create a bootstrap card that can be overridden with precision:

```ruby
# Components::Bootstrap::Card
setup do
  content hidden: true do # hidden: true will cause `render` to skip this content block. You can still use it in the nested fashion.
    div 'I am the default content for the card'
  end

  content :card do
    div class: 'card card-body' do
      content :main
    end
  end
end
```

The output is:

```html
<div class="card card-body"><div>I am the default content for the card</div></div>
```

So when you subclass this component, you can forget about the card and just overwrite `:main` as follows:

```ruby
# Components::Hello::HelloCard < Components::Bootstrap::Card
setup do
  content do # hidden is still true because the old :main content block specified that already.
    h1 'Hello'
    para 'Welcome to my site.'
  end
end
```

The output is:

```html
<div class="card card-body"><h1>Hello</h1><p>Welcome to my site.</p></div>
```

#### Removing content blocks

If a component's parent class defines a content block that is undesired in a subclass component, the content block can be removed as follows:

```ruby
setup do
  remove_content :some_content_defined_in_parent # This component will now behave as if this content block was never declared in its parent.
end
```

### Redirecting away / Intercepting rendering

Immediately before the `content` block(s) are evaluated, another chain of blocks is evaluated if present: `before_render`. If on of these blocks creates a reponse body in the Rails controller, the subsequent `before_render` blocks and all `content` blocks are skipped.

This is useful for redirecting. Here is an example of a component that provides a restaurant's lunch menu, but redirects to the menu overview page instead if it's not lunch time:

```ruby
setup do
  label(:all){ 'Lunch menu' }

  before_render do
    current_time = Time.zone.now
    if current_time.hour >= 11 && current_time.hour < 14
      flash.notice = "Sorry, it's not lunch time."
      redirect_to Compony.path(:index, :menus)
    end
  end

  content do # This is entirely skipped if it's not lunch time.
    h1 label
    para 'Today we have spaghetti.'
  end
end
```

Note how Compony's [path helper](/doc/guide/intents.md#componypath) is used to generate the path. This is the recommended approach to redirecting to a component.

Similarly to `content`, the `before_render` method also accepts a name, defaulting to `:main`, as well as a `before:` keyword. This allows you to selectively extend and/or override `before_render` blocks in subclasses.

[Guide index](/README.md#guide--documentation)