[Back to the guide](/README.md#guide)

# Rails Generators provided by Compony

To make your life easier and coding faster, Compony comes with two generators:

- `rails g component Users::New` will create `app/components/users/new.rb` and, since the component's name coincides with a a pre-built component, automatically inherit from that. If the name is unknown, the generated component will inherit form `Compony::Component` instead. The generator also equips generated components with the boilerplate code that wil be required to make the component work.
  - The generator can also be called via its alternative form `rails g component users/new`.
- `rails g components Users` will generate a set of the most used components.

### Support for custom base components

Generators will automatically detect your `BaseComponents` (see [Inheritance: best practice](./doc/guide/inheritance.md#best-practice)).

[Guide index](/README.md#guide)