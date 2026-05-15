module Compony
  class VirtualModel < ActiveType::Object
    # Use this as a base class whenever you would be inheriting from ActiveType::Object
    # Note: this class is only available in applications that have `active_type` in their Gemfile

    include Compony::ModelMixin
    include Anchormodel::ModelMixin
    include ActiveModel::Attributes

    # `include ActiveModel::Attributes` above shadows `ActiveType::VirtualAttributes#attributes`,
    # which would otherwise merge virtual columns into the returned hash. Without this restoration,
    # attributes declared via `attribute :foo, :type` (routed to `at_attribute` by ActiveType)
    # are written into `@virtual_attributes` but invisible to `#attributes`, breaking callers
    # that do `model.attributes.slice(...)` etc. Mirrors `ActiveType::VirtualAttributes#attributes`.
    def attributes
      self.class._virtual_column_names.each_with_object(super) do |name, attrs|
        attrs[name] = read_virtual_attribute(name)
      end
    end
  end
end
