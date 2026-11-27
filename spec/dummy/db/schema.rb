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

  # Tables for the dependent-record detection specs in spec/compony/model_mixin_spec.rb
  create_table :feasibility_owners, force: true do |t|
    t.string :type
    t.string :code
  end

  create_table :feasibility_items, force: true do |t|
    t.integer :owner_id
    t.string :owner_code
    t.integer :holder_id
    t.string :holder_type
  end
end
