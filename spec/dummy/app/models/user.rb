class User < ApplicationRecord
  field :name, :string
  field :age, :integer
  field :comment, :text
  field :email, :email
  field :admin, :boolean
  field :born_on, :date
  field :margin_relative, :percentage
  field :salary, :currency
  field :homepage, :url
  field :created_at, :datetime

  validates :name, presence: true
  validates :age, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 150 }, allow_nil: true

  prevent :destroy, 'Cannot destroy admins' do
    admin?
  end

  def label
    name
  end
end
