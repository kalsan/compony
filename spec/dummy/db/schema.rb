ActiveRecord::Schema.define do
  create_table :users, force: true do |t|
    t.string :name
    t.integer :age
    t.text :comment
    t.string :email
    t.boolean :admin, default: false, null: false
    t.date :born_on
    t.decimal :margin_relative
    t.decimal :salary
    t.string :homepage
    t.timestamps
  end

  create_table :posts, force: true do |t|
    t.string :title
    t.integer :owner_id
    t.boolean :locked, default: false, null: false
    t.integer :views, default: 0, null: false
  end

  create_table :tags, force: true do |t|
    t.string :name
  end

  create_table :taggings, force: true do |t|
    t.integer :post_id
    t.integer :tag_id
  end
end
