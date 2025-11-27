[Back to the guide](/README.md#guide--documentation)

# Example

To get you a rough idea what working with Compony feels like, let's look at a small dummy application using Compony from scratch, to make this example as explicit as possible. In practice, much of the logic shown here would be moved to abstract components that you can inherit from.

The example is meant to be read top-down and information will mostly not be repeated. Comments will give you a rough idea of what's going on on each line. The features are more completely documented in subsequent chapters.

Please note that from this example alone, you won't be able to comprehend the underlying concepts - refer to the rest of the [guide](/README.md#guide--documentation) for this.

Let's implement a simple user management page with Compony. User's have a name, an integer age, a comment, as well as a role (which we will conveniently model using `AnchorModel`: https://github.com/kalsan/anchormodel). We want to be able to list, show, create, edit and destroy users. Users having the role Admin shall not be destroyed.

## The User model

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

## The Show component

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

    # Intents point to other components. They have a name that is used to identify them and encapsulate both the target component and current context.
    # Exposed intents can be rendered by the application layout.
    exposed_intents do
      add :index, :users # This points to `Components::Users::Index` without passing a model (because it's an index).
      add :edit, @data # This points to `Components::Users::Edit` for the currently loaded model. This also checks feasibility.
    end

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

![Screenshot of our component with an absolutely minimal layout](/doc/imgs/intro-example-show.png)

It is important to note that actions, buttons, navigation, notifications etc. are handled by the application layout. In this and the subsequent screenshots, we explicitely use minimalism, as it makes the generated HTML clearer.

## The Destroy component

Compony has a built-in abstract `Destroy` component which displays a confirmation message and destroys the record if the verb is `DELETE`. This is a good example for how DRY code can become for "boring" components. Since everything is provided with an overridable default, components without special logic can actually be left blank:

```ruby
class Components::Users::Destroy < Compony::Components::Destroy
end
```

Note that this component is fully functional. All is handled by the class it inherits from:

![Screenshot of the destroy component](/doc/imgs/intro-example-destroy.png)

## The New component and the Form component

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

![New form](/doc/imgs/intro-example-new.png)

## The Edit component

Just like `New`, `Edit` is a pre-built component that handles routing and resource manipulation for editing models, combinding the controller actions `edit` and `update` depending on the HTTP verb. It uses that same `Form` component we wrote above and thus the code is as simple as:

```ruby
class Components::Users::Edit < Compony::Components::Edit
end
```

It then looks like this:

![Edit form](/doc/imgs/intro-example-edit.png)

## The Index component

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
      concat render_intent(:new, :users) # The `Users::New` component does not take a model, thus we just pass the symbol `:users`, not a model.

      div class: 'users' do # Opening tag <div class="users">
        @data.each do |user| # Iterate the collection
          div class: 'user' do # For each element, open another div
            User.fields.values.each do |field| # For each user, iterate all fields
              span do # Open a <span> tag
                concat "#{field.label}: #{field.value_for(user)} " # Display the field's label and apply it to value, as we did in the Show component.
              end
            end
            # For each user, add three buttons show, edit, destroy.
            concat render_intent(:show, user, button: { label: { format: :short }})
            concat render_intent(:edit, user, button: { label: { format: :short }})
            concat render_intent(:destroy, user, button: { label: { format: :short }})
          end
        end
      end
    end
  end
end
```

The result looks like this:

![Index component](/doc/imgs/intro-example-index.png)

Note how the admin's delete button is disabled due to the feasibility framework. Pointing the mouse at it causes a tooltip saying: "Cannot destroy admins.", as specified in the model's prevention.

[Guide index](/README.md#guide--documentation)