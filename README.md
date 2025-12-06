<img src="logo.svg" height=250 alt="Compony logo"/>

# Where to read what

- Get to know what Compony is and which concepts it uses in the [README on GitHub](https://github.com/kalsan/compony).
- When using pre-built Components, it is useful to refer to [their setup code](https://github.com/kalsan/compony/tree/main/lib/compony/components).
- There is also a [RubyDoc page for Compony](https://www.rubydoc.info/github/kalsan/compony.git) available.

# About Compony

Compony is a Gem that allows you to write your Rails application in **component-style** fashion. It combines a controller action and route along with its view into a single Ruby class. Along with the DSL approach and a powerful model mixin, Compony **makes your application's code more semantic**, allows writing **much DRYer code**, using inheritance even in views and **much easier refactoring** for your Rails applications, helping you to **keep the code clean as the application evolves**.

Compony's key aspects:

- A Compony component is a single class that exports route(s), controller action(s) and a view to Rails.
  - Refactor common logic into your own components and inherit from them to DRY up your code.
- Compony's model mixin allows you to define metadata in your models and react to them, resulting in more semantic code. Examples:
    - Compony fields capture attributes that should be made visible in your UI. They allow you to implement formatting behavior and parameter sanitization for various types, e.g. URLs, phone numbers, colors etc. ready to be used in your lists, detail panels, or forms.
    - Compony's feasibility framework allows you to prohibit actions based on conditions, along with an error message. This causes all buttons pointing to that action to be disabled with a meaningful error message.
- Compony only structures your code, but provides no style whatsoever. It is like a bookshelf rather than a reader's library. You still implement your own layouts, CSS and Javascript to define the behavior of your front-end.
- Compony seamlessly integrates with Rails and does not interfere with existing code. Using Compony, you **can** write your application as components, but it is still possible to have regular routes, controllers and views side-to-side to it. This way, you can migrate your applications to Compony little by little and enter and leave the Compony world as you please. It is also possible to render Compony components from regular views and vice versa.
- Compony is built for Rails 7, 7.1 and 8, and fully supports Stimulus and Turbo Drive. It is also compatible Turbo Frames and Streams, but there are not many helpers specifically targetting theme at this point..
- Compony uses [CanCanCan](https://github.com/CanCanCommunity/cancancan) for authorization but does not provide an authentication mechanism. You can easily build your own by creating login/logout components that manage cookies, and configure Compony to enforce authentication using the `Compony.authentication_before_action` setter. I have also successfully tested Compony to work with [Devise](https://github.com/heartcombo/devise).

## State of the project

I am actively using this framework in various applications and both performance and reliability are good. However, the project is experimental and lacking peer reviews and especially automatic testing, such as unit and integration tests. Also, expect there to be ([documented](/CHANGELOG.md)) breaking changes in the future, as the API will likely be further refined, resulting in renamings and deprecation of various methods.

## Other projects exploring similar concepts

A project with a similar aim, but a different approach, is [Phlex](https://github.com/phlex-ruby/phlex).

# Guide / Documentation

The following topics should help you get started. Please note that the links will not work in yard doc - read this on [Compony's GitHub repo](https://github.com/kalsan/compony).

- [Self-contained example](./doc/guide/example.md) for those who like to dive straight into code
- [Installation](./doc/guide/installation.md) (start here)
- Concepts and usage:
    - [A basic component](./doc/guide/basic_component.md): Basic concepts relevant for all components
    - [Standalone](./doc/guide/standalone.md): Routing to components
    - [Inheritance](./doc/guide/inheritance.md): DRY up your code by providing base components
    - [Nesting](./doc/guide/nesting.md): How to instanciate components inside other components
    - [Resourceful components](./doc/guide/resourceful.md): How to create components that deal with Rails-style resources
    - [Intents](./doc/guide/intents.md): How to point to a component and provide custom components for rendering intents
    - [Feasibility](./doc/guide/feasibility.md): Disabiling intents based on context (contains `prevent`)
    - [Ownership](./doc/guide/ownership.md): Informing Compony that a resource is conceptually part of another resource
    - [Model fields](./doc/guide/model_fields.md): Allowing Compony to auto-generate UI elements by telling it about the structure of your model
    - [Rails generators](./doc/guide/generators.md): Creating components quickly
    - [Internal datastructures](./doc/guide/internal_datastructures.md): Noteworthy datastructures provided by Compony
    - [Virtual models](./doc/guide/internal_datastructures.md): Unleashing non-persistent interactions through Compony's `ActiveType` integration
- Pre-built components shipped with Compony
    - [Introduction](./doc/guide/pre_built_components.md)
    - [Show](./doc/guide/pre_built_components/show.md): Compony's equivalent to Rail's `show` controller action
    - [Index](./doc/guide/pre_built_components/index.md): Compony's equivalent to Rail's `index` controller action
    - [List](./doc/guide/pre_built_components/list.md): Compony's equivalent to Rail's `_list` partial
    - [Destroy](./doc/guide/pre_built_components/destroy.md): Compony's equivalent to Rail's `destroy` controller action
    - [WithForm](./doc/guide/pre_built_components/with_form.md): A base class for components containing and submitting forms
    - [Form](./doc/guide/pre_built_components/form.md): Compony's equivalent to Rail's `_form` partial
    - [New](./doc/guide/pre_built_components/new.md): Compony's equivalent to Rail's `new` and `create` controller action
    - [Edit](./doc/guide/pre_built_components/new.md): Compony's equivalent to Rail's `edit` and `update` controller action

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
- The feasibility framework does not yet enforce prevention, but only has effects on buttons.
- Compony is not compatible with `tailwindcss-rails`. This is likely due to Tailwind automatically removing any CSS that is not used by the application and the usage detection not picking up Compony components, as their content is not provided in views.

# Acknowledgements

A big thank you to Alex and Koni who have patiently listened to my weird ideas and helped me developing them further, resulting in a few of the key concepts of Compony, such as `param_name`, or the way forms are structured.

Further, it should be acknowledged that Compony would not be what it is if it weren't for the awesome Gems it can rely on, for instance Rails, CanCanCan, SimpleForm, or Schemacop.
