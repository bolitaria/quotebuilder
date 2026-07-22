class CreateOptionValues < ActiveRecord::Migration[8.0]
  def change
    create_table :option_values do |t|
      t.string :name, null: false
      t.decimal :price_modifier, precision: 8, scale: 2, default: 0.0
      t.references :option_group, null: false, foreign_key: true
      t.timestamps
    end
  end
end
