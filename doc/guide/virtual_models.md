[Back to the guide](/README.md#guide--documentation)

# Unleashing virtual models through Compony's `ActiveType` integration

Compony explicitely supports using virtual models using the `active_type` gem for its resourceful components. However, when doing so, your model should inherit from `Compony::VirtualModel` rather than from `ActiveType::Object`.

Combining Compony with virtual models enables programming patterns that are extremely powerful for use cases such as non-persistent wizards, filter forms, stateless launch forms for generators and much more.

For instance, let us consider an application that that generates configurable reports. In this example, the user workflow is to click on a "Generate report" button, fill in a configuration form (what kind of report the generator should produce, what timespan should be considered, which criteria to filter and group by etc.), and, by submitting the form, queueing a job that will perform the report in the background. To realize this, a simple approach would be the following:

- Add the `active_type` gem to your `Gemfile` and run `bundle install`.
- Implement `Components::Reports::Request` which inherits from `Compony::Components::New`.
- In the top section of the component class, define a class `VirtualModel < Compony::VirtualModel` (within the namespace of `Components::Reports::Request`). Use `active_type`'s `attribute` method to add virtual columns for any kind of information your generator will need. Call Compony's `field` method as you would with a normal Rails model and implement any suitable Rails validations. You may even use Rails associations such as `belongs_to` to a real (database-backed) Rails model by implementing an attribute with the following three lines:
    - `attribute :user_id, :bigint` (provided by `active_type`)
    - `belongs_to :user` (provided by Rails)
    - `field :user, :association` (provided by Compony)
- Implement `Components::Reports::RequestForm < Compony::Components::Form` and implement your configuration form there.
- In your `Components::Reports::Request`:
    - Call `standalone path: '/reports/request'` to avoid path conflicts with other components in the `Components::Reports` namespace inheriting from `New`.
    - Call `data_class VirtualModel` to tell the component to use the class you just created within the component's namespace.
    - Call `form_comp_class Components::Reports::RequestForm` to inform the component to use the custom named form.
    - Call something like `label(:all) { ... }` to set a label for your component.
    - Implement `on_created_respond` to create the report job and redirect to a suitable location.

Why this works: As your `Components::Reports::Request` inherits from Compony's `New` component, Compony will believe that the user is about to create a new resource, providing the Compony equivalents for the Rails controller actions `new` and `create`. When the user submits the form, Compony will run validations, re-render the form with error messages if they fail, or otherwise call `@data.save` which does nothing since the model is only virtual. This is why you take back control by overriding the `on_created_respond` block, which is called only if all validations have passed.

Note: it is even possible to combine this pattern with Rails' `accepts_nested_attributes_for` and `simple_form`'s `f.simple_fields_for` call, where the nested object is a real database-backed model. Even though the component's resource is purely virtual, Rails will create or update the nested model when Compony calls `save` on the parent resource. This allows for very fast implementation of business logic creating multiple objects from a single form post by wrapping the resources in a virtual model.

If you intend to use this technique in combination with `ActiveStorage`, you must also override the `store_data` block to just validate the model instead of saving it, as the hook creating the attachment is bound to fail (the virtual model does not exist in the database and thus cannot be referenced from `ActiveStorage::Attachment`). For the same reason, you cannot call `blob.download`, but must find the file's tempfile in the request parameters in order to process the file attached by the user.

[Guide index](/README.md#guide--documentation)