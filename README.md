TODO: Write this

Notes:

- `model` is an ApplicationModel or similar (e.g. ActiveType, but not guarantted to work at this point), `.model_name` is important
- `data` can be model or models
- To redirect instead of rendering, use `before_render` if the redirect is conditional (e.g. if validation passes), or `respond` if always redirecting.
  - As a rule of thumb, use `before_render` if there is a `content` block (even by inheritance) and `respond` otherwise.
- To protect a custom controller by Compony authentication, use in the controller: `before_action Compony.authentication_before_action`

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
- Compony is built for Rails 7 and fully supports Stimulus and Turbo Drive. Turbo Frames and Streams are not yet targetted, so Compony is currently meant for websites where every click triggers a "full page load" (in quotes because they are not actually full page loads due to Turbo Drive).
- Compony uses CanCanCan (https://github.com/CanCanCommunity/cancancan) for authorization but does not provide an authentication mechanism. You can easily build your own by creating login/logout components that manage cookies, and configure Compony to enforce authentication using the `Compony.authentication_before_action` setter.

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

  # Components are configured in the `setup` method, which prevents loading order isues.
  setup do
    # The DSL call `label` defines what what is the title of the component and which text is displayed on links and buttons pointing to it.
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

Here is what our Show component looks like when we a layout with the bare minimum and no styling at all:

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
    # The generatd underlying implementation is Schemacop V3 (https://github.com/sitrox/schemacop/blob/master/README_V3.md).
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

## Installing cancancan

Create the file `app/models/abilty.rb` with the following content:

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

If you have abstract components (i.e. components that your app never uses directly, but which you inherit from), you may name and place them arbitrarly.

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
    h1 'Welcome to my basic component'
    para "It's not much, but it's honest work."
  end
end
```

If a subclass component calls `content`, it overwrites the block of the parent class, replacing the entire content. To make overwriting more granular, you can use `add_content` instead of `content`. This method can be called multiple times to create an array of content. If no argument is specified, the new content is placed at the bottom. Otherwise, it is inserted at the indicated position. Example:

```ruby
setup do
  content do
    h1 'Welcome to my basic component'
  end
  add_content do
    para 'Thank you and see you tomorrow.'
  end
  add_content 1 do
    para 'This paragraph is inserted between the others.'
  end
end
```

The result is the h1 with index 0, then the paragraph reading "This paragraph..." with index 1, and finally "Thank you..." with index 2.

#### Redirecting away / Intercepting rendering

Immediately before the `content` block(s) are evaluated, another block is evaluated if present: `before_render`. If this block creates a reponse body in the Rails controller, the content blocks are skipped.

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

### Standalone

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

#### Exposing multiple paths in the same component (calling standalone multiple times)

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
      respond do # Again: overriding `respond` skips authorization! This is why we don't need to provide an `authroize` block here.
        controller.render(json: MapTiler.load(params, current_ability)) # current_ability is provided by CanCanCan and made available by Compony.
      end
    end
  end

  # More code for labelling, content etc.
end
```

Please note that the idea here is to package things that belong together, not to provide different kinds of content in a single component. For displaying different pages, use multiple components and have eatch expose a single route.

#### Naming of exposed routes

The routes to standalone components are named and you can point to them using Rails' `..._path` and `..._url` helpers. The naming scheme is: `[standalone]_[component]_[family]_comp`. Examples:

- Default standalone: `Components::Users::Index` exports `index_users_comp` and thus `index_users_comp_path` can be used.
- Named standalone: If `standalone :foo, path: ...` is used, the exported name is `foo_index_users_comp`.

#### Handling formats

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

#### Redirect in `respond` or in `before_render`?

Rails controller redirects can be issued both in a verb DSL's `respond` block and in `before_render`. The rule of thumb that tells you which way to go is:

- If you want to redirect depending on the HTTP verb, use `respond`.
- If you want to redirect depending on params, state, time etc.  **independently of the HTTP verb**, use `before_render`, as this is more convenient than writing a standalone -> verb -> respond tree.

### Compony helpers, buttons and links

TODO

### Nesting

TODO

Note that only the root component runs authentication and authorization. Thus, be careful which components you nest.

#### Actions

TODO

## Resourceful components

TODO

Note that only the root component loads and stores data. TODO: say something about resourceful_sub_comp

## Inheritance

TODO

## Pre-build components shipped with Compony

TODO

## Fields

TODO

## The feasibility framework

TODO

## Internal datastructures

TODO

### MethodAccessibleHash

TODO

### RequestContext

TODO

## Generators

TODO

# Contributing

TODO

# Caveats

- The API is not yet as consistent as I'd like it. Examples:
  - `content` replaces the content and `add_content` inserts some, but for actions the insertion is called `action`.
  - Every DSL call, in particular nested ones, should be able to insert and/or override a precise call in the parent class. Override behavior should be made consistent across the entire Compony DSL. For instance, it makes no sense that `add_content` uses an index while `action` uses `before` with a keyword.
  - Instead of `skip_...` methods, `remove_...` should be implemented. This allows yet another level of classes to re-add properties. Skipping should be kept for options given via the constructor.
- At this point, I haven't gotten into Turbo Streams and Turbo Frames. It would be interesting to exend Compony such it also makes writing applications using these features much easier.
- The feasibility framework does not yet enforce prevention, but only has effects on buttons. Actions should be structured more explicitely such that prevention becomes as tight as authorization.