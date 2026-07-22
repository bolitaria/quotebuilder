class CreateQuotes < ActiveRecord::Migration[8.0]
  def change
    create_table :quotes do |t|
      t.string :customer_name, null: false
      t.string :customer_email, null: false
      t.string :status, default: 'draft'
      t.decimal :total_price, precision: 10, scale: 2
      t.references :product, null: false, foreign_key: true
      t.jsonb :configuration_data, default: {}
      t.timestamps
    end
    add_index :quotes, :status
  end
end
