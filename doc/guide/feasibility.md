[Back to the guide](/README.md#guide--documentation)

# Feasibility

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

**Note that the feasibility framework currently only affects buttons/links pointing to actions, not the action itself.** If a user were to issue the HTTP call manually, the component happily responds and performs the action. This is why you should always back important preventions with an appropriate Rails model validation:

- The Rails model validation prevents that invalid data can be saved to the database.
- The feasibility framework disables buttons and links and explains to guide the user.
- Links are disabled by changing the href to `'#'` and adding the `.disabled` class, which is useful when bootstrap is used.
- Authorization is orthogonal to this, limiting the actions of a specific user.
- If an action is both prevented and not authorized, the authorization "wins" and the action button is not shown at all.

Compony has a feature that auto-detects feasibility of some actions. In particular, it checks for `dependent` relations in the `has_one`/`has_many` relations and disables delete buttons that point to objects that have dependent objects that cannot automatically be destroyed.

To disable auto detection, call `skip_autodetect_feasibilities` in your model.

[Guide index](/README.md#guide--documentation)