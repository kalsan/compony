module Compony
  class VirtualModel < ActiveType::Object
    # Use this as a base class whenever you would be inheriting from ActiveType::Object
    # Note: this class is only available in applications that have `active_type` in their Gemfile

    include Compony::ModelMixin
    include Anchormodel::ModelMixin
    include ActiveModel::Attributes
  end
end
