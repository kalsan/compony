[Back to the guide](/README.md#guide--documentation)

# Ownership

Ownership is a concept that captures the nature of data to be presented by Compony. It means that an object only makes sense within the context of another that it belongs to. Owned objects have therefore no index component, because they don't have meaning on their own. For instance:

- typically NOT owned: visitors and vouchers: while a voucher can `belong_to` a visitor, the voucher can be managed on it's own. Vouchers can have their own index page which makes it possible to search for a given voucher code across all vouchers.
- typically owned: users and their permissions: a permission only makes sense with respect to its associated user and having a list of all permissions across the system would rarely be a use case. In this case, we consider the `Permission` model to be conceptually **owned by** the `User` model.

In Compony, if a model class is owned by another, it means that:

- The owned model has a non-optional `belongs_to` relation ship to its owner.
- The owned model class has no Index component.
- Pre-built components (more on them later) offer [exposed intents](/doc/guide/intents.md#exposed-intents) to the owner model and redirect to its Show component instead of to the current object's Index component.

To mark a model as owned by another, write the following code **in the model**:

```ruby
# app/models/permission.rb
owned_by :user
```

[Guide index](/README.md#guide--documentation)