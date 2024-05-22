<img src="logo.svg" height=250 alt="Compony logo"/>

- To see the README including images, refer to https://github.com/kalsan/compony
- To see the class documentation, refer to https://www.rubydoc.info/github/kalsan/compony

# Introduction

Compony is a Gem that allows you to write your Rails application in component-style fashion. It combines a controller action and route along with its view into a single Ruby class. This allows writing much DRYer code, using inheritance even in views and much easier refactoring for your Rails applications, helping you to keep the code clean as the application evolves.

Compony's key aspects:

- A Compony component is a single class that exports route(s), controller action(s) and a view to Rails.
  - Refactor common logic into your own components and inherit from them to DRY up your code.
- Compony's powerful model mixin allows you to define metadata in your models and react to them. Examples:
  - Compony fields capture attributes that should be made visible in your UI. They allow you to implement formatting behavior and parameter sanitization for various types, e.g. URLs, phone numbers, colors etc. ready to be used in your lists, detail panels, or forms.
  - Compony's feasibility framework allows you to prohibit actions based on conditions, along with an error message. This causes all buttons pointing to that action to be disabled with a meaningful error message.
- Compony only structures your code, but provides no style whatsoever. It is like a bookshelf rather than a reader's library. You still implement your own layouts, CSS and Javascript to define the behavior of your front-end.
- Using Compony, you **can** write your application as components, but it is still possible to have regular routes, controllers and views side-to-side to it. This way, you can migrate your applications to Compony little by little and enter and leave the Compony world as you please. It is also possible to render Compony components from regular views and vice versa.
- Compony is built for Rails 7 and fully supports Stimulus and Turbo Drive. Turbo Frames and Streams are not yet targeted, so Compony is currently meant for websites where every click triggers a "full page load" (in quotes because they are not actually full page loads due to Turbo Drive).
- Compony uses [CanCanCan](https://github.com/CanCanCommunity/cancancan) for authorization but does not provide an authentication mechanism. You can easily build your own by creating login/logout components that manage cookies, and configure Compony to enforce authentication using the `Compony.authentication_before_action` setter. We have also successfully tested Compony to work with [Devise](https://github.com/heartcombo/devise).

## State of the project

I am actively using this framework in various applications and both performance and reliability are good. However, the project is at an early stage and is lacking peer reviews and especially automatic testing, such as unit and integration tests. Also, expect there to be (documented) breaking changes in the future, as the API will likely be further refined, resulting in renamings and deprecation of various methods.

## Example

To get you a rough idea what working with Compony feels like, let's look at a small dummy application using Compony from scratch, to make this example as explicit as possible. In practice, much of the logic shown here would be moved to abstract components that you can inherit from.

The example is meant to be read top-down and information will mostly not be repeated. Comments will give you a rough idea of what's going on on each line. The features are more completely documented in subsequent chapters.

Let's implement a simple user management page with Compony. User's have a name, an integer age, a comment, as well as a role (which we will conveniently model using `AnchorModel`: https://github.com/kalsan/anchormodel). We want to be able to list, show, create, edit and destroy users. Users having the role Admin shall not be destroyed.

### The User model

We'll assume a model that has the standard Rails schema:

```ruby
create_table 'users', force: :cascade do |t|
    t.string 'name'
    t.string 'comment'
    t.integer 'age'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.string 'role', default: 'guest', null: false
  end
```

```ruby
class User < ApplicationRecord
  # Refer to https://github.com/kalsan/anchormodel
  belongs_to_anchormodel :role

  # Fields define which attributes are relevant in the GUI and how they should be presented.
  field :name, :string
  field :age, :integer
  field :comment, :string
  field :role, :anchormodel
  field :created_at, :datetime
  field :updated_at, :datetime

  # The method `label` must be implemented on all Compony models. Instead of this method, we could also rename the column :name to :label.
  def label
    name
  end

  # This is how we tell Compony that admins are not to be destroyed.
  prevent :destroy, 'Cannot destroy admins' do
    role == Role.find(:admin)
  end
end
```

### The Show component

This components loads a user by reading the param `id`. It then displays a simple table showing all the fields defined above.

We will implement this component on our own, giving you an insight into many of Compony's mechanisms:

```ruby
# All components (except abstract ones) must be placed in the `Components` namespace living under `app/components`.
# They must be nested in another namespace, called "family" (here, `Users`), followed by the component's name (here, `Show`).
class Components::Users::Show < Compony::Component
  # The Resourceful mixin causes a component to automatically load a model from the `id` parameter and store it under `@data`.
  # The model's class is inferred from the component's name: `Users::Show` -> `User`
  include Compony::ComponentMixins::Resourceful

  # Components are configured in the `setup` method, which prevents loading order issues.
  setup do
    # The DSL call `label` defines what is the title of the component and which text is displayed on links as well as buttons pointing to it.
    # It accepts different formats and takes a block. Given that this component always loads one model, the block must take an argument which is the model.
    # The argument must be provided by links and buttons pointing to this component.
    label(:short) { |_u| 'Show' } # The short format is suitable for e.g. a button in a list of users.
    label(:long) { |u| "Show user #{u.label}" } # The long format is suitable e.g. in a link in a text about this user.

    # Actions point to other components. They have a name that is used to identify them (e.g. in the `prevent` call above) and a block returning a button.
    # Compony buttons take the name to an action and either a family name or instance, e.g. a Rails model instance.
    # Whether or not an instance must be passed is defined by the component the button is pointing to (see the comment for `label` earlier in the example).
    action(:index) { Compony.button(:index, :users) } # This points to `Components::Users::Index` without passing a model (because it's an index).
    action(:edit) { Compony.button(:edit, @data) } # This points to `Components::Users::Edit` for the currently loaded model. This also checks feasibility.

    # When a standalone config is present, Compony creates one or multiple Rails routes. Components without standalone config must be nested within others.
    standalone path: 'users/show/:id' do # This specifies the path to this component.
      verb :get do # This speficies that a GET route should be created for the path specified above.
        authorize { true } # Immediately after loading the model, this is called to check for authorization. `true` means that anybody can get access.
      end
    end

    # After loading the model and passing authorization, the `content` block is evaluated. This is Compony's equivalent to Rails' views.
    # Inside the `content` block, the templating Gem Dyny (https://github.com/kalsan/dyny) is used, allowing you to write views in plain Ruby.
    content do
      h3 @data.label # Display a <h3> title
      table do # Open a <table> tag
        tr do # Open a <tr> tag
          # Iterate over all the fields defined in the model above and display its translated label (this uses Rails' `human_attribute_name`), e.g. "Name".
          @data.fields.each_value { |field| th field.label }
        end # Closing </tr>
        tr do
          # Iterate over the fields again and call `value_for` which formats each field's value according to the field type.
          @data.fields.each_value { |field| td field.value_for(@data) }
        end
      end
    end
  end
end
```

Here is what our Show component looks like when we have a layout with the bare minimum and no styling at all:

![Screenshot of our component with an absolutely minimal layout](doc/imgs/intro-example-show.png)

It is important to note that actions, buttons, navigation, notifications etc. are handled by the application layout. In this and the subsequent screenshots, we explicitely use minimalism, as it makes the generated HTML clearer.

### The Destroy component

Compony has a built-in abstract `Destroy` component which displays a confirmation message and destroys the record if the verb is `DELETE`. This is a good example for how DRY code can become for "boring" components. Since everything is provided with an overridable default, components without special logic can actually be left blank:

```ruby
class Components::Users::Destroy < Compony::Components::Destroy
end
```

Note that this component is fully functional. All is handled by the class it inherits from:

![Screenshot of the destroy component](doc/imgs/intro-example-destroy.png)

### The New component and the Form component

Compony also has a pre-built abstract `New` component that handles routing and resource manipulation. It combines the controller actions `new` and `create`, depending on the HTTP verb of the request. Since it's pre-built, any "boring" code can be omitted and our `New` components looks like this:

```ruby
class Components::Users::New < Compony::Components::New
end
```

By default, this component looks for another component called `Form` in the same directory, which can look like this:

```ruby
class Components::Users::Form < Compony::Components::Form
  setup do
    # This mandatory DSL call prepares and opens a form in which you can write your HTML in Dyny.
    # The form is realized using the simple_form Gem (https://github.com/heartcombo/simple_form).
    # Inside this block, more DSL calls are available, such as `field`, which automatically generates
    #    a suitable simple_form input from the field specified in the model.
    form_fields do
      concat field(:name) # `field` checks the model to find out that a string input is needed here. `concat` is the Dyny equivalent to ERB's <%= %>.
      concat field(:age)
      concat field(:comment)
      concat field(:role) # Compony has built-in support for Anchormodel and as the model declares `role` to be of type `anchormodel`, a select is rendered.
    end

    # This DSL call is mandatory as well and automatically generates strong param validation for this form.
    # The generated underlying implementation is Schemacop V3 (https://github.com/sitrox/schemacop/blob/master/README_V3.md).
    schema_fields :name, :age, :comment, :role
  end
end
```

This is enough to render a fully functional form that creates new users:

![New form](doc/imgs/intro-example-new.png)

### The Edit component

Just like `New`, `Edit` is a pre-built component that handles routing and resource manipulation for editing models, combinding the controller actions `edit` and `update` depending on the HTTP verb. It uses that same `Form` component we wrote above and thus the code is as simple as:

```ruby
class Components::Users::Edit < Compony::Components::Edit
end
```

It then looks like this:

![Edit form](doc/imgs/intro-example-edit.png)

### The Index component

This component should list all users and provide buttons to manage them. We'll build it from scratch and make it resourceful, where `@data` holds the ActiveRecord relation.

```ruby
class Components::Users::Index < Compony::Component
  # Making the component resourceful enables a few features for dealing with @data.
  include Compony::ComponentMixins::Resourceful

  setup do
    label(:all) { 'Users' } # This sets all labels (long and short) to 'Users'. When pointing to this component using buttons, we will not provide a model.
    standalone path: 'users' do # The path is simply /users, without a param. This conflicts with `Resourceful`, which we will fix in `load_data`.
      verb :get do
        authorize { true }
      end
    end

    # This DSL call is specific to resourceful components and overrides how a model is loaded.
    # The block is called before authorization and must assign a model or collection to `@data`.
    load_data { @data = User.all }

    content do
      h4 'Users:' # Provide a title
      # Provide a button that creates a new user. Note that we must write `:users` (plural) because the component's family is `Users`.
      concat compony_button(:new, :users) # The `Users::New` component does not take a model, thus we just pass the symbol `:users`, not a model.

      div class: 'users' do # Opening tag <div class="users">
        @data.each do |user| # Iterate the collection
          div class: 'user' do # For each element, open another div
            User.fields.values.each do |field| # For each user, iterate all fields
              span do # Open a <span> tag
                concat "#{field.label}: #{field.value_for(user)} " # Display the field's label and apply it to value, as we did in the Show component.
              end
            end
            # For each user, add three buttons show, edit, destroy. The method `with_button_defaults` applies its arguments to every `compony_button` call.
            # The option `format: :short` causes the button to call the target component's `label(:short) {...}` label function.
            Compony.with_button_defaults(label_opts: { format: :short }) do
              concat compony_button(:show, user) # Now equivalent to: `compony_button(:show, user, label_opts: { format: :short })`
              concat compony_button(:edit, user)
              concat compony_button(:destroy, user)
            end
          end
        end
      end
    end
  end
end
```

The result looks like this:

![Index component](doc/imgs/intro-example-index.png)

Note how the admin's delete button is disabled due to the feasibility framework. Pointing the mouse at it causes a tooltip saying: "Cannot destroy admins.", as specified in the model's prevention.

# Alternatives to Compony

A project with a similar aim, but much more mature, is [Phlex]( https://github.com/phlex-ruby/phlex).

# Installation

## Installing Compony

First, add Compony to your Gemfile:

```ruby
gem 'compony'
```

Then run `bundle install`.

Create the directory `app/components`.

In `app/models/application_record.rb`, add the following line below `primary_abstract_class`:

```ruby
include Compony::ModelMixin
```

## Installing CanCanCan

Create the file `app/models/ability.rb` with the following content:

```ruby
class Ability
  include CanCan::Ability

  def initialize(_user)
    can :manage, :all
  end
end
```

This is an initial dummy ability that allows anyone to do anything. Most likely, you will want to adjust the file. For documentation, refer to [https://github.com/CanCanCommunity/cancancan/](https://github.com/CanCanCommunity/cancancan/).

## Optional: installing anchormodel

To take advantage of the anchormodel integration, follow the installation instructions under [https://github.com/kalsan/anchormodel/](https://github.com/kalsan/anchormodel/).

# Usage

Compony components are nestable elements that are capable of replacing Rails' routes, views and controllers. They structure code for data manipulation, authentication and rendering into a single class that can easily be subclassed. This is achieved with Compony's DSL that provides a readable and overridable way to store your logic.

Just like Rails, Compony is opinionated and you are advised to structure your code according to the examples and explanations. This makes it easier for others to dive into existing code.

## A basic (bare) component

### Naming

Compony components must be named according to the pattern `Components::FamilyName::ComponentName`.

- The family name should be pluralized and is analog to naming a Rails controller. For instance, when you would create a `UsersController` in plain Rails, the Compony family equivalent is `Users`.
- The component name is the Compony analog to a Rails action.

Example: If your plain Rails `UsersController` has an action `show`, the equivalent Compony component is `Components::Users::Show` and is located under `app/components/users/show.rb`.

If you have abstract components (i.e. components that your app never uses directly, but which you inherit from), you may name and place them arbitrarily.

### Initialization, manual instantiation and rendering

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

Typically, your components will be instantiated and rendered by Compony through the "standalone" feature explained below. Nonetheless, it is possible to do so manually as well, for instance if you'd like to render a component from within an existing view in your application:

```erb
<% index_users_comp = Components::Users::Index.new %>
<%= index_users_comp.render(controller) %>
```

Note that rendering a component always requires the controller as an argument. It also possible to pass an argument `locals` that will be made available to `render` (see below):

```erb
<% index_users_comp = Components::Users::Index.new %>
<%= index_users_comp.render(controller, locals: { weather: :sunny }) %>
```

### Setup

Every component must call the static method `setup` which will contain most of the code of your components. This can be achieved either by a call directly from your class, or by inheriting from a component that calls `setup`. If both classes call the method, the inherited class' `setup` is run first and the inheriting's second, thus, the child class can override setup properties of the parent class.

Call setup as follows:

```ruby
class Components::Users::Show < Compony::Component
  setup do
    # Your setup code goes here
  end
end
```

The code in setup is run at the end the component's initialization. In this block, you will call a number of methods that define the component's behavior and which we will explain now.

#### Labelling

This defines a component's label, both as seen from within the component and from the outside. You can query the label in order to display it as a title in your component. Links and buttons to components will also display the same label, allowing you to easily rename a component, including any parts of your UI that point to it.

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

It is important to note that since your label block takes an argument, you must provide the argument when reading the label (exception: if the component implements the method `data` returning an object, the argument can be omitted and the label block will be provided that object). Only up to one argument is supported.

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

#### Providing content

Basic components do not come with default content. Instead, you must call the method `content` inside the setup block and provide a block containing your view. It will be evaluated inside a `RequestContext` (more on that later).

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

As you see, overusing this feature can lead to messy code as it becomes unclear what happens in what order. For this reason, this feature should only be used to decouple the content of your abstract components for allowing surgical overrides in subclasses.

It is a good convention to always have one content block named `:main`, as you might want to refer to it in subclasses.

#### Redirecting away / Intercepting rendering

Immediately before the `content` block(s) are evaluated, another chain of blocks is evaluated if present: `before_render`. If on of these blocks creates a reponse body in the Rails controller, the subsequent `before_render` blocks and all `content` blocks are skipped.

This is useful for redirecting. Here is an example of a component that provides a restaurant's lunch menu, but redirects to the menu overview page instead if it's not lunch time:

```ruby
setup do
  label(:all){ 'Lunch menu' }

  before_render do
    current_time = Time.zone.now
    if current_time.hour >= 11 && current_time.hour < 14
      flash.notice = "Sorry, it's not lunch time."
      redirect_to all_menus_path
    end
  end

  content do # This is entirely skipped if it's not lunch time.
    h1 label
    para 'Today we have spaghetti.'
  end
end
```

Similarly to `content`, the `before_render` method also accepts a name, defaulting to `:main`, as well as a `before:` keyword. This allows you to selectively extend and/or override `before_render` blocks in subclasses.

## Standalone

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

The standalone DSL has more features than those presented in the minimal example above. Excluding resourceful features (which we will cover below), the full list is:

- `standalone` can be called multiple times, for components that need to expose multiple paths, as described below. Inside each `standalone` call, you can call:
  - `skip_authentication!` which disables authentication, in case you provided some. You need to implement `authorize` regardless.
  - `layout` which takes the file name of a Rails layout and defaults to `layouts/application`. Use this to have your Rails application look differently depending on the component.
  - `verb` which takes an HTTP verb as a symbol, one of: `%i[get head post put delete connect options trace patch]`. `verb` can be called up to once per verb. Inside each `verb` call, you can call (in the non-resourceful case):
    - `authorize` is mandatory and explained above.
    - `respond` can be used to implement special behavior that in plain Rails would be placed in a controller action. The default, which calls `before_render` and the `content` blocks, is usually the right choice, so you will rarely implement `respond` on your own. See below how `respond` can be used to handle different formats or redirecting clients. **Caution:** `authorize` is evaluated in the default implementation of `respond`, so when you override that block, you must perform authorization yourself!

### Exposing multiple paths in the same component (calling standalone multiple times)

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

### Naming of exposed routes

The routes to standalone components are named and you can point to them using Rails' `..._path` and `..._url` helpers. The naming scheme is: `[standalone]_[component]_[family]_comp`. Examples:

- Default standalone: `Components::Users::Index` exports `index_users_comp` and thus `index_users_comp_path` can be used.
- Named standalone: If `standalone :foo, path: ...` is used within `Components::Users::Index`, the exported name is `foo_index_users_comp`.

### Handling formats

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

### Redirect in `respond` or in `before_render`?

Rails controller redirects can be issued both in a verb DSL's `respond` block and in `before_render`. The rule of thumb that tells you which way to go is:

- If you want to redirect depending on the HTTP verb, use `respond`.
- If you want to redirect depending on params, state, time etc.  **independently of the HTTP verb**, use `before_render`, as this is more convenient than writing a standalone -> verb -> respond tree.

## Inheritance

When inheriting from another component class, `setup` can be called in the child as well in order to overwrite specified configurations. The parent's `setup` block will be run first, then the child's, then the grand-child's and so on.

Omit any configuration that you want to keep from the parent class. For instance, if your parent's setup looks like this:

```ruby
setup do
  standalone path: 'foo/bar' do
    layout 'funky'
    verb :get do
      authorize { true }
    end
  end
  content do
    h1 'Test'
  end
end
```

Assuming you want to implement a child class that only differs by layout and adds more content below "test", you can implement:

```ruby
setup do
  standalone do
    layout 'dark'
  end
  content :below do
    para 'This will appear below "Test".'
  end
end
```

### Un-exposing a component

If a component's parent class is standalone but the child should not be, use `clear_standalone!`:

```ruby
setup do
  clear_standalone!
end
```

## Nesting

Components can be arbitrarily nested. This means that any component exposing content can instantiate an arbitrary number of sub-components that will be rendered as part of its own content. This results in a component tree. Sub-components are aware of the nesting and even of their position within the parent. The topmost component is called the **root component** and it's the only component that must be standalone. If you instead render the topmost component from a custom view, there is conceptually no root component, but Compony has no way to detect this special case.

Nesting is orthogonal to inheritance, they are two entirely different concepts. For disambiguating "parent component", we will make an effort to apply that term to nesting only, while writing "parent component class" if inheritance is meant.

Sub-components are particularly useful for DRYing up your code, e.g. when a visual element is used in multiple places of your application or even multiple times on the same page.

Nesting occurs when a component is being rendered. It is perfectly feasible to use an otherwise standalone component as a sub-component. Doing so simply plugs it into the content of another component and any arguments can be given to its constructor.

Note that only the root component runs authentication and authorization. Thus, be careful which components you nest.

To create a sub-component, use `sub_comp` in a component's content block. Any keyword arguments given will be passed to the sub-component. It is strictly recommended to exclusively use `sub_comp` (or its resourceful pendent, see below) to nest components, as this method makes a component aware of its exact nesting.

Here is a simple example of a component that displays numbers as binary:

```ruby
# app/components/numbers/binary.rb
class Components::Nestings::Binary < Compony::Component
  def initialize(*args, number: nil, **kwargs, &block)
    @number = nil # If this component is initialized with the argument `number`, it will be stored in the component instance.
  end
  setup do
    # standalone and other configs are omitted in this example.
    content do
      # If the initializer did not store `number`, check whether the Rails request contains the parameter `number`:
      # Note: do not do that, as we will demonstrate below.
      @number ||= params[:number].presence&.to_i || 0
      # Display the number as binary
      para "The number #{@number} has the binary form #{@number.to_s(2)}."
    end
  end
end
```

If used standalone, the number can be set by using a GET parameter, e.g. `?number=5`. The result is something like this:

```text
The number 5 has the binary form 101.
```

Now, let's write a component that displays three different numbers side-by-side:

```ruby
# app/components/numbers/binary_comparator.rb
class Components::Nestings::BinaryComparator < Compony::Component
  setup do
    # standalone and other configs are omitted in this example.
    content do
      concat sub_cop(Components::Nestings::Binary, number: 1).render(controller)
      concat sub_cop(Components::Nestings::Binary, number: 2).render(controller)
      concat sub_cop(Components::Nestings::Binary, number: 3).render(controller)
    end
  end
end
```

The result is something like this:

```text
The number 1 has the binary form 1.
The number 2 has the binary form 10.
The number 3 has the binary form 11.
```

However, this is static and no fun. We cannot use the HTTP GET parameter any more because all three `Binary` sub-components listen to the same parameter `number`. To fix this, we will need to scope the parameter using the `param_name` as explained in the next subsection.

### Proper parameter naming for (nested) components

As seen in above, even components can be arbitrarily nested, making it harder to identify which HTTP GET parameter in the request is intended for which component. To resolve this, Compony provides nesting-aware scoping of parameter names:

- Each component has an `index`, given to it by the `sub_comp` call in the parent, informing it witch n-th child of the parent it is.
  - For instance, in the example above, the three `Binary` components have indices 0, 1 and 2.
- Each component has an `id` which corresponds to `"#{family_name}_#{comp_name}_#{@index}"`.
  - For instance, the last `Binary` component from the example above has ID `nestings_binary_2`.
  - The `BinaryComparator` has ID `nestings_binary_comparator_0`.
- Each component has a `path` indicating its exact position in the nesting tree as seen from the root component.
  - In the example above, the last `Binary` component has path `nestings_binary_comparator_0/nestings_binary_2`.
  - `BinaryComparator` has path `nestings_binary_comparator_0`.
- Each component provides the method `param_name` that takes the name of a parameter name and prepends the first 5 characters of the component's SHA1-hashed path to it.
  - For instance, if `param_name(:number)` is called on the last `Binary` component, the output is `a9f3d_number`.
  - If the same method is called on the first `Binary` component, the output is `f6e86_number`.

In short, `param_name` should be used to prefix every parameter that is used in a component that could potentially be nested. It is good practice to apply it to all components. `param_name` has two important properties:

- From the param name alone, it is not possible to determine to which component the parameter belongs. However:
- `param_name` is consistent across reloads of the same URL (given that the components are still the same) and thus each component will be able to identify its own parameters and react to them.

With that in mind, let's adjust our `Binary` component. In this example, we will assume that we have implemented yet another component called `NumberChooser` that provides a number input with a Stimulus controller attached. That controller is given the parameter as a String value, such that the it can set the appropriate HTTP GET param and trigger a full page reload to the `BinaryComparator` component.

Further, we can drop the custom initializer from the `Binary` component, as the number to display is exclusively coming from the HTTP GET param. The resulting code looks something like:

```ruby
# app/components/numbers/binary_comparator.rb
class Components::Nestings::BinaryComparator < Compony::Component
  setup do
    # standalone and other configs are omitted in this example.
    content do
      3.times do
        concat sub_cop(Components::Nestings::Binary).render(controller)
      end
    end
  end
end

# app/components/numbers/binary.rb
class Components::Nestings::Binary < Compony::Component
  setup do
    # standalone and other configs are omitted in this example.
    content do
      # This is where we use param_name to retrieve the parameter for this component, regardless whether it's standalone or used as a sub-comp.
      @number ||= params[param_name(:number)].presence&.to_i || 0
      # Display the number as binary
      para "The number #{@number} has the binary form #{@number.to_s(2)}."
      # Display the number input that will reload the page to adjust to the user input. We give it the param_name such that it can set params accordingly.
      concat sub_comp(Components::Nestings::NumberChooser, param_name: param_name(:number))
    end
  end
end
```

The result for the URL `path/to/binary_comparator?a9f3d_number=2&e70b4_number=4&a9f3d_number=8` is something like this:

```text
The number 2 has the binary form 10. Enter a number and press ENTER: [2]
The number 4 has the binary form 100. Enter a number and press ENTER: [4]
The number 8 has the binary form 1000. Enter a number and press ENTER: [8]
```

Note that this example is completely stateless, as all the info is encoded in the URL.

## Resourceful components

So far, we have mainly seen how to present static content, without considering how loading and storing data is handled. Whenever a component is about data, be it a collection (e.g. index, list) or a single instance (e.g. new, show, edit, destroy, form), that component typically becomes resourceful. In order to implement a resourceful component, include the mixin `Compony::ComponentMixins::Resourceful`.

Resourceful components use an instance variable `@data` and provide a reader `data` for it. As a convention, always store the data the component "is about" in this variable.

Further, the class of which `data` should be can be specified and retrieved by using `data_class`. By default, `data_class` is inferred from the component's family name, i.e. `Components::User::Show` will automatically return `User` as `data_class`.

The mixin adds extra hooks that can be used to store logic that can be executed in the request context when the component is rendered standalone. The formulation of that sentence is important, as the decision which of these blocks are executed depends on the verb DSL. But before elaborating on that, let's first look at all the available hooks provided by the Resourceful mixin:

- `load_data`: Important. Specify a block that assigns something to `@data` here. The block will be run before authorization - thus, you can check `@data` for authorizing (e.g. `can?(:read, @data)`).
- `after_load_data`: Optional. If a block is specified, it is run immediately after `load_data`. This is useful if you inherit from a component that loads data but you need to alter something, e.g. refining a collection.
- `assign_attributes`: Important for components that alter data, e.g. New, Edit. Specify a block that assigns attributes to your model from `load_data`. The model is now dirty, which is important: **do not save your model here**, as authorization has not yet been performed. Also, **do not forget to validate params before assigning them to attributes**.
- `after_assign_attributes`: Optional. If a block is specified, it is run immediately after `assign_attributes`. Its usage is similar to that of `after_load_data`.
- (At this point, your `authorize` block is executed, throwing a `CanCan::AccessDenied` exception causing HTTP 403 not authorized if the block returns false.)
- `store_data`: Important for components that alter data, e.g. New, Edit. This is where you save your model stored in `@data` to the database.

Another important aspect of the Resourceful mixin is that it also **extends the Verb DSL** available in the component. The added calls are:

- `load_data`
- `assign_attributes`
- `store_data`

Unlike the calls above, which are global for the entire component, the ones in the Verb DSL are on a per-verb basis, same as the `authorize` call. If the same hook is both given as a global hook and in the Verb DSL, the Verb DSL hook overwrites the global one. The rule of thumb on where to place logic is:

- If multiple verbs use the same logic for a hook, place it in the global hook. For example, let us consider an Edit component: if GET is called on it, the model is loaded and parameters are assigned to it in order to fill the form's inputs. If PATCH is called, the exact same thing is done before attempting to save the model. In this case, you would implement both `load_data` and `assign_attributes` as global hooks.
- If a hook is specific to a single verb, place it in the verb config.

Let's build an example of a simplified Destroy component. In practice, you'd instead inherit from `Compony::Components::Destroy`. However, for the sake of demonstration, we will implement it from scratch:

```ruby
class Components::Users::Destroy < Compony::Component
  # Make the component resourceful
  include Compony::ComponentMixins::Resourceful

  setup do
    # Let the path be of the form users/42/destroy
    standalone path: 'users/:id/destroy' do
      verb :get do
        # In the case of a GET request, ask for confirmation, not deleting anything.
        # Nevertheless, we should authorize :destroy, not :read.
        # Reason: this way, buttons pointing to this component will not be shown
        # to users which lack the permission to destroy @data.
        authorize { can?(:destroy, @data) }
      end

      verb :delete do
        # In the case of a DELETE request, the record will be destroyed.
        authorize { can?(:destroy, @data) }
        store_data { @data.destroy! }
        # We overwrite the respond block because we want to redirect, not render
        respond do
          flash.notice = "#{@data.label} was deleted."
          redirect_to Compony.path(:index, :users)
        end
      end
    end

    # Resourceful components have a default `load_data` block that loads the model.
    # Therefore, the default behavior is already set to:
    # load_data { @data = User.find(params[:id]) }

    label(:short) { |_| 'Delete' }
    label(:long) { |data| "Delete #{data.label}" }
    content do
      h1 "Are you sure to delete #{@data.label}?"
      div compony_button(:destroy, @data, label: 'Yes, delete', method: :delete)
    end
  end
end
```

### Complete resourceful lifecycle

This graph documents a typical resourceful lifecycle according to which Compony's pre-built components (see below) are implemented.

- `load_data` creates or fetches the resource from the database.
- `after_load_data` can refine the resource, e.g. add scopes to a relation.
- `assign_attributes` takes the HTTP parameters, validates them and assigns them to the resource.
- `after_assign_attributes` can refine the assigned resource, e.g. provide defaults for blank attributes.
- `authorize` is called.
- `store_data` creates/updates/destroys the resource.
- `respond` typically shows a flash and redirects to another component.

![Graph of the complete resourceful lifecycle](doc/resourceful_lifecycle.png)

### Nesting resourceful components

As mentioned earlier, hooks such as those provided by Resourceful typically run only when a component is accessed standalone. This means that in a nested setting, only the component running those hooks is the root component.

When nesting resourceful components, it is therefore best to load all necessary data in the root component. Make sure to include any relations used by sub-components in order to avoid "n+1" queries in the database.

`resourceful_sub_comp` is the resourceful sibling of `sub_comp` and both are used the same way. Under the hood, the resourceful call passes two extra parameters to the sub component: `data` and `data_class`.

The rule of thumb thus becomes:

- When a resourceful component instantiates a resourceful sub-component, use `resourceful_sub_comp` in the parent component.
- When a resourceful component instantiates a non-resourceful sub-component, use `sub_comp`.
- The situation where a non-resourceful component instantiates a resourceful component should not occur. Instead, make your parent component resourceful, even if it doesn't use the data itself. By housing a resourceful sub-comp, the parent component's nature inherently becomes resourceful and you should use the Resourceful mixin.

## Compony helpers, links and buttons

When pointing to or instantiating a component, writing the whole class name would be cumbersome. For this reason, Compony has several helpers that will retrieve the correct class for you. The most important ones are explained in this subsection. The terms are defined as follows:

- Component name or constant: For a component `Components::Users::Show`, this would be `'Show'`, `'show'`, or `:show`
- Family name or constant: For a component `Components::Users::Show`, this would be `'Users'`, `'users'`, or `:users`
- Model: an instance of a class that implements the `model_name` method in the same way as `ActiveRecord::Base` does. For helpers that support giving models, Compony will use `model_name` to auto-infer the family name. This requires you to name the component according to convention, i.e. the family name must match the model's pluralized camelized `model_name`.

### Getting the class of a component

- `Compony.comp_class_for(comp_name_or_cst, model_or_family_name_or_cst)` returns the class or nil if not found.
- `Compony.comp_class_for!(comp_name_or_cst, model_or_family_name_or_cst)` returns the class. If the class is not found, an error will be raised.

Example:

```ruby
my_component = Compony.comp_class_for!(:show, User.first).new
my_component.class # Components::Users::Show
```

#### Getting a path to a component

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

### Generating a link to a component

In order to allow a user to visit another component, don't implement your links and buttons manually. Instead, use Compony's links and buttons, as those extract information from the target component, avoiding redundant code and making refactoring much easier.

Compony comes with the view helper `compony_link` that is available in any of your views, including a component's `content` blocks. The link's label is inferred from the component the link points to. `compony_link` is used as follows:

- To generate a link to a non-resourceful component, pass the family name.
- To generate a link to a resourceful component, prefer passing an instance instead of a family name. More precisely, you must pass an instance if the component's label requires an argument.

Any additional arguments passed to `compony_link` will be given to Rails' `link_to` method, allowing you to set parameters, HTTP method, terget, rel etc.

Examples:

```ruby
compony_link(:index, :users) # "View all users" -> 'users/index'
compony_link(:index, :users, label_opts: { format: :short }) # "All" -> 'users/index'
compony_link(:show, User.first) # "View John Doe" -> 'users/show/1'
compony_link(:destroy, User.first, method: :delete) # "Delete John Doe" -> 'users/destroy/1'

# NOT working:
compony_link(:show, :users, id: 1) # Error: The label for the Users::Show component takes an argument which was not provided (the user's label)
```

### Generating a button to a component

Compony buttons are components that render a button to another component. While the view helper `compony_button` works similar to `compony_link`, you can also manually instantiate a button and work with it like with any other component.

Similar to links, Compony buttons take a component name and either a family or model. The label, path, method and title (i.e. tooltip) can be overwritten by passing the respective arguments as shown below.

Compony buttons have a type that is either `:button` or `:submit`. While the first works like a link redirecting the user elsewhere, the second is used for submitting forms. It can be used inside a `form_for` or `simple_form_for`.

A compony button figures out on it's own whether it's clickable or not:

- Buttons can be disabled explicitly by passing `enabled: false` as a parameter.
- If a user is not authorized to access the component a button is pointing to, the button is not displayed.
- If the target component should not be accessible due to a prevention in the feasibility framework (explained later), the button is disabled and a tooltip is shown explaining why the button is not clickable.

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

#### Implementing custom buttons

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

## Actions

The word "actions" is heavily overused, so here is a disambiguation:

- Rails controller actions: a method that is implemented in a Rails controller
- CanCanCan actions: the first method to CanCanCan's `can?` method
- Compony actions: buttons that point to other components

At this point, Compony actions are a loose concept, which will likely be refined in the future. Currently, Compony actions are defined as buttons that point to other components. These buttons can be disabled by the prevention framework (explained below).

### Defining and manipulating root actions

In addition to regular buttons that are rendered as part of the content blocks, components can expose root actions with the `actions` call. Root actions will only be rendered if the component they are defined in is currently the root component.

To have a component expose a root action, call the method `action` in a `setup` block and return a Compony button:

```ruby
setup do
  action :edit do
    Compony.button(:edit, @data)
  end

  action :destroy do
    Compony.button(:destroy, @data)
  end
end
```

The name of the action ("back" in the example above) allows you to refer to that action in a component inheriting from this one:

```ruby
# Assuming that this component inherits from the example above
setup do
  skip_action :destroy

  action :overview, before: :edit do
    Compony.button(:index, :users, label: 'Overview')
  end
end
```

In this example, two actions will be shown: overview and edit.

An action button can be disabled through the prevention framework (explained below). However, it can also instead be hidden completely by returning nil from within the action block:

```ruby
action :edit do
  next if @data.locked?
  Compony.button(:edit, @data)
end
```

The action in this example will be skipped entirely if `locked?` returns true.

### Displaying root actions

Root actions are not shown by default in Compony because layouting is up to you. In order to display the root component's actions, add the following view helper call to your layout:

```erb
<%# layouts/application.html.erb %>
...
<%= compony_actions %>
```

If there is currently no root component, or if the root component defines no actions, this does nothing. However, if there are root actions available, the Compony buttons returned by the root component will be rendered.

## The feasibility framework

When a user has the permission to perform an action in general, but it is currently not feasible (for instance if the concerned object is incomplete, or if right now is not the right time to do the action), buttons pointing to that action should be disabled and a HTML `title` attribute should cause a tooltip explaining why this action cannot be performed right now.

This can be easily achieved with the feasibility framework, which allows you to prevent actions on conditions, along with an error message. Formulate the error message similar to Rails validation errors (first letter not capital, no period at the end), as the prevention framework is able to concatenate multiple error messages if multiple conditions prevent an action.

The feasibility framework currently only makes sense for resourceful components.

Example:

```ruby
# app/models/user.rb
# Prevent sending an e-mail to a user that has no e-mail address present
prevent :send_mail, 'the e-mail address is missing' do
  email.blank?
end

# app/models/event.rb
# Multiple actions can be prevented at once:
# Prevent creating or removing a booking to an event that lies in the past or that is locked
prevent [:create_booking, :destroy_booking], 'the event is already over' do
  ends_at < Time.zone.now || locked?
end
```

**Note that the feasibility framework currently only affects buttons pointing to actions, not the action itself.** If a user were to issue the HTTP call manually, the component happily responds and performs the action. This is why you should always back important preventions with an appropriate Rails model validation:

- The Rails model validation prevents that invalid data can be saved to the database.
- The feasibility framework disables buttons and explains to guide the user.
- Authorization is orthogonal to this, limiting the actions of a specific user.
- If an action is both prevented and not authorized, the authorization "wins" and the action button is not shown at all.

Compony has a feature that auto-detects feasibility. In particular, it checks for `dependent` relations in the `has_one`/`has_many` relations and disables delete buttons that point to objects that have dependent objects that cannot automatically be destroyed.

To disable auto detection, call `skip_autodetect_feasibilities` in your model.

## Ownership

Ownership is a concept that captures the nature of data to be presented by Compony. It means that an object only makes sense within the context of another that it belongs to. Owned objects have therefore no index component, because they don't have meaning on their own. For instance:

- typically NOT owned: visitors and vouchers: while a voucher can `belong_to` a visitor, the voucher can be managed on it's own. Vouchers can have their own index page which makes it possible to search for a given voucher code across all vouchers.
- typically owned: users and their permissions: a permission only makes sense with respect to its associated user and having a list of all permissions across the system would rarely be a use case. In this case, we consider the `Permission` model to be conceptually **owned by** the `User` model.

In Compony, if a model class is owned by another, it means that:

- The owned model has a non-optional `belongs_to` relation ship to its owner.
- The owned model class has no Index component.
- Pre-built components (more on them later) offer root actions to the owner model and redirect to its Show component instead of to the current object's Index component.

To mark a model as owned by another, write the following code **in the model**:

```ruby
# app/models/permission.rb
owned_by :user
```

## Fields

Compony fields are your models' attributes that you wish to expose in your application's UI. They are a central place to store important information about those attributes, accessible from everywhere and without the need for a database connection.

Every Compony field must define at least a name and type. Compony types and ActiveRecord types are similar but not equivalent. While ActiveRecord uses types for storing data in the DB, Compony fields use them for presenting it. For instance, the Compony "string" type covers any kind of string, including ActiveRecord's "string", "text" etc. Similarly, Compony has no "numeric" type - use "integer" or "decimal" instead, depending on whether or not you want to show decimals or not. There are additional field types like "color", "url" etc. You can find a complete list of all Compony field types in the module `Compony::ModelFields`.

Compony fields support Postgres arrays (non-nested).

A particularly interesting model field is `Association` which handles `belongs_to`, `has_many` and `has_one` associations, automatically resolving the association's nature and providing links to the appropriate component.

Every Compony field can further take an arbitrary amount of additional named arguments. Those can be retrieved by calling `YourRailsModel.fields[:field_name].extra_attrs`.


Here is an example call to fields for a User model:

```ruby
# app/models/user.rb
class User < ApplicationRecord
  field :first_name, :string
  field :last_name, :string
  field :user_role, :anchormodel
  field :website, :url
  field :created_at, :datetime
  field :updated_at, :datetime
end
```

Compony fields provide the following features:

- a label that lets you generate a name for the column: `User.fields[:first_name].label`
- `value_for`: given a model instance, formats the data (e.g. a field of type "url" will produce a link).
- Features for forms:
  - `simpleform_input` auto-generates in input for a simple form (from the `simple_form` gem).
  - `simpleform_input_hidden` auto-generates a hidden input.
  - `schema_line` auto-generates a DSL call for Schemacop v3 (from the `schemacop` gem), which is useful for parameter validation.

You can then use these fields in other components, for instance a list as described in the example at the top of this guide:

```ruby
User.fields.values.each do |field|
  span do
    concat "#{field.label}: #{field.value_for(user)} " # Display the field's label and apply it to value
  end
end
```

### Implementing your own fields

You can implement your own model fields. Make sure they are all within the same namespace and inherit at least from `Compony::ModelFields::Base`. To enable them, write an initializer that overwrites the array `Compony.model_field_namespaces`. Namespaces listed in the array are prioritized from first to last. If a field (e.g. `String`) exists in multiple declared namespaces, the first will be used. This allows you to overwrite Compony fields.

Example:

```ruby
# config/initializers/compony.rb
Compony.model_field_namespaces = ['MyCustomModelFields', 'Compony::ModelFields']
```

You can then implement `MyCustomModelFields::Animal`, `MyCustomModelFields::String` etc. You can then use `field :fav_animal, :animal` in your model.

## Pre-built components shipped with Compony

Compony comes with a few pre-built components that cover the most common cases that can be speed up development. They are meant to be inherited from and the easiest way to do this is by using the Rails generator `rails new component` (described below).

The pre-built components can be found in the module `Compony::Components`. As you can see, there is no Show and no Index component. The reason is that these will depend a lot on your application's UI framework (e.g. Bootstrap) and thus the benefits a UI-agnostic base component can provide are minimal. Additionally, these components are very easy to implement, as is illustrated in the example at the beginning of this documentation.

In the following, the pre-built components currently shipped with Compony are presented.

### Button

As stated earlier, buttons are just regular components that rendered in-place. They don't make use of nesting logic (and presumably never will), and thus they are rendered as-is, without `sub_comp`.

You will rarely (or probably never) instantiate a button on your own, but use helpers like `Compony.button` or `compony_button`. For this reason, the documentation for instantiating buttons is located in the section documenting those helpers above.

### Destroy

This component is the Compony equivalent to a typical Rails controller's `destroy` action.

`Compony::Components::Destroy` is a resourceful standalone component that listens to two verbs:

- GET will cause the Destroy component to ask if the resource should be destroyed, along with a button pointing to the DELETE verb. If the record does not exist, a HTTP 404 code is returned.
- DELETE will `destroy!` the resource, show a flash and redirect to:
  - if present: the data's Show component
  - otherwise: the data's Index component

Authorization checks for `destroy` even in GET. The reason is that users that aren't able to destroy a resource shouldn't even arrive at the page asking them whether they want to do so, unable to click the only button due to lacking permissions. This also causes any `compony_link` and `compony_button` to Destroy components to be hidden if the user is unable to destroy the corresponding resource.

This component largely follows the resourceful lifecycle, explained in above under "Resourceful". As can be expected, the resource is loaded by `Resourceful`'s default load block and `store_data` is implemented to destroy the resource.

If the resource is owned (see "Ownership" documentation above), the component provides a `:back_to_owner` root action in the form of a cancel button.

The following DSL methods are implemented to allow for convenient overrides of default logic:

- The block `on_destroyed` is evaluated between successful record destruction and responding. By default, it is not implemented and doing so is optional. This would be a suitable location for hooks that update state after a resource was destroyed (like an `after_destroy` hook, but only executed if a record was destroyed by this component). Do not redirect or render here, use the next blocks instead.
- The block given in `on_destroyed_respond` is evaluated after destruction and by default shows a flash, then redirects. The redirection is performed with HTTP code 303 ("see other") in oder to force a GET request. This is required for the component to work with Turbo. Overwrite this block if you need to completely customize all logic that happens after destruction. If this block is overwritten, `on_destroyed_redirect_path` will not be called.
- `on_destroyed_redirect_path` is evaluated as the second step of `on_destroyed_respond` and redirects to the resource's Show or Index component as described above. Overwrite this block in order to redirect to another component instead, while keeping the default flash provided by `on_destroyed_respond`.

### WithForm

`Compony::Components::WithForm` is an abstract base class for components that render a form. Those components can further be resourceful, but don't have to be. If a component inherits from WithForm, it is always twinned with another component that will provide the form.

WithForm adds the following DSL methods:

- `form_comp_class` sets the class that will be instantiated by `form_comp`
- `form_comp` returns an instance of the Form component twinned with this component. If `form_comp_class` was never set, it will default to loading the component named `Form` in the same family as this component.
- `submit_verb` takes a symbol containing a verb, e.g. `:patch`. It defines this component's standalone verb that should be called when the twinned Form component is submitted.
- `submit_path` defaults to this component's standalone path. You can override this to submit the form to another component, should you need it.

### Form

This component holds a form and should only be instantiated by the `form_comp` call of a component that inherits from WithForm.

`Compony::Components::Form` is an abstract base class for any components presenting a regular form. This class comes with a lot of tooling for rendering forms and inputs, as well as validating parameters. When the component is rendered, the Gem SimpleForm is used to create the actual form: [https://github.com/heartcombo/simple_form](https://github.com/heartcombo/simple_form).

Parameters are structured like typical Rails forms. For instance, if you have a form for a `User` model and the attribute is `first_name`, the parameter looks like `user[first_name]=Tom`. In this case, we will call `user` the `schema_wrapper_key`. Parameters are validated using Schemacop: [https://github.com/sitrox/schemacop](https://github.com/sitrox/schemacop).

The following DSL calls are provided by the Form component:

- Required: `form_fields` takes a block that renders the inputs of your form. More on that below.
- Optional: `skip_autofocus` will prevent the first input to be auto-focussed when the user visits the form.
- Typically required: `schema_fields` takes the names of fields as a whitelist for strong parameters. Together with model fields, this will completely auto-generate a Schemacop schema suitable for validating this form. If your argument list gets too long, you can use multiple calls to `schema_field` instead to declare your fields one by one on separate lines.
- Optional: `schema_line` takes a single Schemacop line. Use this for custom whitelisting of an argument, e.g. if you have an input that does not have a corresponding model field.
- Optional: `schema` allows you to instead fully define your own custom Schemacop V3 schema manually. Note that this disables all of the above schema calls.

The `form_fields` block acts much like a content block and you will use Dyny there. Two additional methods are made available exclusively inside the block:

- `field` (not to be confused with the model mixin's static method) takes the name of a model field and auto-generates a suitable SimpleForm input as defined in the field's type.
- `f` gives you direct access to the `simple_form` instance. You can use it to write e.g. `f.input(...)`.

Here is a simple example for a form for a sample user:

```ruby
class Components::Users::Form < Compony::Components::Form
  setup do
    form_fields do
      concat field(:first_name)
      concat field(:last_name)
      concat field(:age)
      concat field(:comment)
      concat field(:role)
    end
    schema_fields :first_name, :last_name, :age, :comment, :role
  end
end
```

Note that the inputs and schema are two completely different concepts that are not auto-inferred from each other. You must make sure that they always correspond. If you forget to mention a field in `schema_fields`, posting the form will fail. Luckily, Schemacop's excellent error messaging will explain which parameter is prohibited.

### New

This component is the Compony equivalent to a typical Rails controller's `new` and `create` actions.

`Compony::Components::New` is a resourceful standalone component based on WithForm that listens to two verbs:

- GET will cause the New component to create a fresh instance of its `data_class` and render the form.
- POST (equivalent to a `create` action in a controller) will attempt to save the resource. If that fails, the form is rendered again with a HTTP 422 code ("unprocessable entity"). If the creation succeeds, a flash is shown and the user is redirected:
  - if present: the data's Show component
  - otherwise, if the resource is owned by another resource class: the owner's Show component
  - otherwise, the data's Index component

Authorization checks for `create` even in GET. The reason is that it makes no sense to present an empty form to a user who cannot create a new record. This also causes any `compony_link` and `compony_button` to New components to be hidden to users lacking the permission.

This component follows the resourceful lifecycle, explained in above under "Resourceful". `load_data` is set to create a new record and `store_data` attempts to create it. Parameters are validated in `assign_attributes` using a Schemacop schema that is generated from the form. The schema corresponds to Rail's typical strong parameter structure for forms. For example, a user's New component would look for a parameter `user` holding a hash of attributes (e.g. `user[first_name]=Tom`).

In case you overwrite `store_data`, make sure to set `@created_succeeded` to true if storing was successful (and to set it to false otherwise).

The following DSL calls are implemented to allow for convenient overrides of default logic:

- The block `on_create_failed_respond` is run if `@create_succeeded` is not true. By default, it logs all error messages with level `warn` and renders the component again through HTTP 422, causing Turbo to correctly display the page. Error messages are displayed by the form inputs.
- The block `on_created` is evaluated between successful record creation and responding. By default, it is not implemented and doing so is optional. This would be a suitable location for hooks that update state after a resource was created (like an `after_create` hook, but only executed if a record was created by this component). Do not redirect or render here, use the next blocks instead.
- The block given in `on_created_respond` is evaluated after successful creation and by default shows a flash, then redirects. Overwrite this block if you need to completely customize all logic that happens after creation. If this block is overwritten, `on_created_redirect_path` will not be called.
- `on_created_redirect_path` is evaluated as the second step of `on_created_respond` and redirects to the resource's Show, its owner's Show, or its own Index component as described above. Overwrite this block in order to redirect ot another component instead, while keeping the default flash provided by `on_created_respond`.

### Edit

This component is the Compony equivalent to a typical Rails controller's `edit` and `update` actions.

`Compony::Components::Edit` is a resourceful standalone component based on WithForm that listens to two verbs:

- GET will cause the Edit component to load a record given by ID and render the form based on that record. If the record does not exist, a HTTP 404 code is returned.
- PATCH (equivalent to a `update` action in a controller) will attempt to save the resource. If that fails, the form is rendered again with a HTTP 422 code ("unprocessable entity"). If the update succeeds, a flash is shown and the user is redirected:
  - if present: the data's Show component
  - otherwise, if the resource is owned by another resource class: the owner's Show component
  - otherwise, the data's Index component

Unlike in New and Destroy, Edit's authorization checks for `edit` in GET and for `update` in PATCH. This enables you to "abuse" an Edit component to double as a Show component. Users having only `:read` permission will not see any links or buttons pointing to an Edit component. Users having only `:edit` permissions can see the form (including the data) but not submit it. Users having `:write` permissions can edit and update the Resource, in accordance to CanCanCan's `:write` alias.

This component follows the resourceful lifecycle, explained in above under "Resourceful". Parameters are validated in `assign_attributes` using a Schemacop schema that is generated from the form. The schema corresponds to Rail's typical strong parameter structure for forms. For example, a user's Edit component would look for a parameter `user` holding a hash of attributes (e.g. `user[first_name]=Tom`).

In case you overwrite `store_data`, make sure to set `@update_succeeded` to true if storing was successful (and to set it to false otherwise).

The following DSL calls are implemented to allow for convenient overrides of default logic:

- The block `on_update_failed_respond` is run if `@update_succeeded` is not true. By default, it logs all error messages with level `warn` and renders the component again through HTTP 422, causing Turbo to correctly display the page. Error messages are displayed by the form inputs.
- The block `on_updated` is evaluated between successful record creation and responding. By default, it is not implemented and doing so is optional. This would be a suitable location for hooks that update state after a resource was updated (like an `after_update` hook, but only executed if a record was updated by this component). Do not redirect or render here, use the next blocks instead.
- The block given in `on_updated_respond` is evaluated after successful creation and by default shows a flash, then redirects. Overwrite this block if you need to completely customize all logic that happens after creation. If this block is overwritten, `on_updated_redirect_path` will not be called.
- `on_updated_redirect_path` is evaluated as the second step of `on_updated_respond` and redirects to the resource's Show, its owner's Show, or its own Index component as described above. Overwrite this block in order to redirect ot another component instead, while keeping the default flash provided by `on_updated_respond`.

## Generators

To make your life easier and coding faster, Compony comes with two generators:

- `rails g component Users::New` will create `app/components/users/new.rb` and, since the component's name coincides with a a pre-built component, automatically inherit from that. If the name is unknown, the generated component will inherit form `Compony::Component` instead. The generator also equips generated components with the boilerplate code that wil be required to make the component work.
  - The generator can also be called via its alternative form `rails g component users/new`.
- `rails g components Users` will generate a set of the most used components.

## Internal datastructures

Compony has a few internal data structures that are worth mentioning. Especially when building your own UI framework on top of Compony, these might come in handy.

### MethodAccessibleHash

This is a simpler and safer version of [OpenStruct](https://github.com/ruby/ostruct), allowing you to access a hash's keys via method accessors.

Usage example:

```ruby
default_options = { foo: :bar }
options = Compony::MethodAccessibleHash.new(default_options)
options[:color] = :green
options.foo # => :bar
options.color # => green
```

This part of Compony is also made available under the MIT license at: [https://gist.github.com/kalsan/87826048ea0ade92ab1be93c0919b405](https://gist.github.com/kalsan/87826048ea0ade92ab1be93c0919b405).

### RequestContext

The content blocks, as well as Form's `form_fields` block all run within a `Compony::RequestContext`, which encapsulates useful methods for accessing data within a request. RequestContext is a Dslblend object and contains all the magic described in [https://github.com/kalsan/dslblend](https://github.com/kalsan/dslblend).

The main provider (refer to the Dslblend documentation to find out what that means) is set to the component. Additional providers are controller's helpers, the controller itself, as well as custom additional providers that can be fed to RequestContext in the initializer.

To instantiate a RequestContext, the following arguments must be given:

- The first argument must be the component instantiating the RequestContext.
- The second argument must be the controller holding the current HTTP request.
- Optional: any further arguments will be given to Dslblend as additional providers.
- Optional: the keyword argument `helpers` can be given to overwrite the `helpers` context. If not given, the helpers will be extracted from the controller.
- Optional: the keyword argument `locals` can be given a hash of local assigns to be made available within the context.

RequestContext further provides the following methods on its own:

- `controller` returns the controller.
- `helpers` returns the helpers (either from the initializer or the controller).
- `local_assigns` returns the locals that can be given to the RequestContext on instantiation through the `locals` keyword argument.
- `evaluate_with_backfire` is `evaluate` with enabled backfiring.
- `component` returns the component the RequestContext was instantiated with.
- `request_context` returns self. This is for disambiguation purposes.
- Any call to an unknown method will first be evaluated as a potential hit in `locals`. Only if no matching local is found, Dslblend takes over.

# Contributing

Compony is Free Software under the LGPLv3 and you are most welcome to contribute to it.

- If you spotted a security vulnerability, **do not open an issue** but instead use the contact form at [https://kalsan.ch/#contact](https://kalsan.ch/#contact) instead (English is just fine, even if the website is in German).
- If you'd like to contribute feedback or discuss something, please open an issue.
- If you have an idea that is worth implementing, please fork the repo, implement your changes in your own fork, and open a pull request.

# Caveats

- The API is not yet as consistent as I'd like it. Examples:
  - Instead of `skip_...` methods, `remove_...` should be implemented. This allows yet another level of classes to re-add properties. Skipping should be kept for options given via the constructor.
  - Change resourceful hooks as follows:
    - Verb DSL hooks still take precedence over global hooks, but if given, they MUST provide a block.
    - If global hooks are present, they will be executed in every verb.
- At this point, I haven't gotten into Turbo Streams and Turbo Frames. It would be interesting to extend Compony such it also makes writing applications using these features much easier.
- Feasibility:
  - The feasibility framework does not yet enforce prevention, but only has effects on buttons. Actions should be structured more explicitly such that prevention becomes as tight as authorization.
  - Feasibility for links is not yet implemented.

# Acknowledgements

A big thank you to Alex and Koni who have patiently listened to my weird ideas and helped me developing them further, resulting in a few of the key concepts of Compony, such as `param_name`, or the way forms are structured.

Further, it should be acknowledged that Compony would not be what it is if it weren't for the awesome Gems it can rely on, for instance Rails, CanCanCan, SimpleForm, or Schemacop.
