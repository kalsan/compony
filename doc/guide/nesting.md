[Back to the guide](/README.md#guide--documentation)

# Nesting

Components can be arbitrarily nested. This means that any component exposing content can instantiate an arbitrary number of sub-components that will be rendered as part of its own content. This results in a component tree. Sub-components are aware of the nesting and even of their position within the parent. The topmost component is called the **root component** and it's the only component that must be standalone. If you instead render the topmost component from a custom view, there is conceptually no root component, but Compony has no way to detect this special case.

Nesting is orthogonal to inheritance, they are two entirely different concepts. For disambiguating "parent component", we will make an effort to apply that term to nesting only, while writing "parent component class" if inheritance is meant.

Sub-components are particularly useful for DRYing up your code, e.g. when a visual element is used in multiple places of your application or even multiple times on the same page.

Nesting occurs when a component is being rendered. It is perfectly feasible to use an otherwise standalone component as a sub-component. Doing so simply plugs it into the content of another component and any arguments can be given to its constructor.

Note that only the root component runs authentication and authorization. Thus, be careful which components you nest.

To create a sub-component, use `render_sub_comp` in a component's content block. Any keyword arguments given will be passed to the sub-component. It is strictly recommended to exclusively use `render_sub_comp`, `sub_comp` or its [resourceful](./resourceful.md#nesting-resourceful-components) pendent to nest components, as this method makes a component aware of its exact nesting.

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
      concat render_sub_comp(Components::Nestings::Binary, number: 1)
      concat render_sub_comp(Components::Nestings::Binary, number: 2)
      concat render_sub_comp(Components::Nestings::Binary, number: 3)
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

## Proper parameter naming for (nested) components

As seen above, components can be arbitrarily nested, making it harder to identify which HTTP GET parameter in the request is intended for which component. To resolve this, Compony provides nesting-aware scoping of parameter names:

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
        concat render_sub_comp(Components::Nestings::Binary)
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

## Rendering `List` as sub comp in `Show`

A pattern often used is the following:

```ruby
class Components::Users::Show < Compony::Components::Show
  setup do
    content :quotes do
      h1 "Quotes of #{@data.label}"
      concat render_sub_comp(:list, @data.quotes.accessible_by(current_ability), turbo_frame: :"user_#{@data.id}_quotes")
    end
  end
end
```

Again, there is a lot going on here:

- Since the component inherits from the [pre-built Show component](/doc/guide/pre_built_components/show.md), it automatically displays all fields of user in its `main` content block.
- We add a second content block `:quotes` with a title displaying "Quotes of John Deer" and tell compony to render the appropriate list as a sub comp, giving it all quotes of John Deer that are accessible by the user currently logged in (this is a cancancan feature).
- `render_sub_comp` is thus given an `ActiveRecord` collection of `Quote` models and it builts an [Intent](/doc/guide/intents.md) to figure out that `Components::Quotes::List` is the component that will be instanciated, given the appropriate quotes, and rendered here.
- We also give `:"user_#{@data.id}_quotes"` to the parameter `turbo_frame`, which causes `render_sub_comp` to place the sub comp inside a frame that is named something like `:user_1_quotes`. Since compony's [pre-built List component](/doc/guide/pre_built_components/list.md) contains search and filter forms, the turbo frame makes sure that anything entered there does not interfere with other parameters.

[Guide index](/README.md#guide--documentation)