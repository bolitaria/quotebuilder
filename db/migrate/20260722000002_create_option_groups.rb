class CreateOptionGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :option_groups do |t|
      t.string :name, null: false
      t.references :product, null: false, foreign_key: true
      t.timestamps
    end
  end
end
