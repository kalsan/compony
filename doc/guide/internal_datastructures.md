[Back to the guide](/README.md#guide--documentation)

# Internal datastructures

Compony has a few internal data structures that are worth mentioning. Especially when building your own UI framework on top of Compony, these might come in handy.

## MethodAccessibleHash

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

## RequestContext

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

[Guide index](/README.md#guide--documentation)