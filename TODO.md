- When cancelling in an owned form, prefer Show instead of owner.Index
- Come up with something like `data_class(BaseClass){ attribute(:foo) }` -> ActiveType
- Docs: mine real-world Compony usage from existing Rails applications, extract recurring
  patterns, fully anonymize them (no app/author/business specifics), and document the
  useful/important ones in the guide (feeds the cookbook + thickened pre-built docs).
  Reflect the firm conventions: prefer pre-built CRUD components + `render_intent` over
  custom endpoints; components live in the family of the model they act on; virtual form
  fields via ActiveType/VirtualModel, never `attr_accessor` on models.