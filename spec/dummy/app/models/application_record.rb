class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
  include Compony::ModelMixin
end
