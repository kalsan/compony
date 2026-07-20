ActiveRecord::Schema.define do
  create_table :users, force: true do |t|
    t.string :name
    t.integer :age
    t.text :comment
    t.string :email
    t.boolean :admin, default: false, null: false
    t.date :born_on
    t.timestamps
  end
end
