class Post < ApplicationRecord
  belongs_to :owner, class_name: 'User', optional: true
  has_many :taggings, dependent: :destroy
  has_many :tags, through: :taggings

  field :title, :string
  field :owner, :association
  field :tags, :association
  field :locked, :boolean

  def label
    title
  end
end
