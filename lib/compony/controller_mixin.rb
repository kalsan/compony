module Compony
  module ControllerMixin
    extend ActiveSupport::Concern

    include Compony::ViewHelpers

    included do
      # Declare all methods in each such module as helper_method
      Compony::ViewHelpers.public_instance_methods.each { |helper_method_sym| helper_method helper_method_sym }
    end
  end
end
