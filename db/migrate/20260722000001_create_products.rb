class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.decimal :base_price, precision: 10, scale: 2, null: false, default: 0.0
      t.string :category
      t.timestamps
    end
    add_index :products, :code, unique: true
  end
end
