- [Back to the guide](/README.md#guide--documentation)
- [List of pre-built components](/doc/guide/pre_built_components.md)

# Pre-built components: List

This resourceful component displays a table / list of records. It is meant to be nested within another component, typically [`Index`](./index.md) of the same family or [`Show`](./show.md) of another family. Compony's implementation of this component features:

- Inferrence of rows from model fields as well as custom rows
- Row actions for each displayed record
- Pagination
- Sorting: if the Ransack gem is installed and at least one sorting column has been specified, the component can automatically generate a select input for sorting as well as sorting links.
- Filtering / Searching: if the Ransack gem is installed and at least one filter has been specified, the component can automatically generate a filter / search form that works with Ransack.

This component serves as a base block for building powerful management interfaces. Consult the component's class to learn about the various methods you can use in `setup` in order to customize the behavior. You will likely want to implement your own custom base component based on this component and overwrite the `content` blocks that you would like to customize.