class CreateQuoteItems < ActiveRecord::Migration[8.0]
  def change
    create_table :quote_items do |t|
      t.references :quote, null: false, foreign_key: true
      t.references :option_value, null: false, foreign_key: true
      t.timestamps
    end
  end
end
