class AddPdfPathToQuotes < ActiveRecord::Migration[8.1]
  def change
    add_column :quotes, :pdf_path, :string
  end
end
