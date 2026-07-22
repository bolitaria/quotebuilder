# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_07_22_162746) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "option_groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "product_id", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_option_groups_on_product_id"
  end

  create_table "option_values", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "option_group_id", null: false
    t.decimal "price_modifier", precision: 8, scale: 2, default: "0.0"
    t.datetime "updated_at", null: false
    t.index ["option_group_id"], name: "index_option_values_on_option_group_id"
  end

  create_table "products", force: :cascade do |t|
    t.decimal "base_price", precision: 10, scale: 2, default: "0.0", null: false
    t.string "category"
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_products_on_code", unique: true
  end

  create_table "quote_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "option_value_id", null: false
    t.bigint "quote_id", null: false
    t.datetime "updated_at", null: false
    t.index ["option_value_id"], name: "index_quote_items_on_option_value_id"
    t.index ["quote_id"], name: "index_quote_items_on_quote_id"
  end

  create_table "quotes", force: :cascade do |t|
    t.jsonb "configuration_data", default: {}
    t.datetime "created_at", null: false
    t.string "customer_email", null: false
    t.string "customer_name", null: false
    t.string "pdf_path"
    t.bigint "product_id", null: false
    t.string "status", default: "draft"
    t.decimal "total_price", precision: 10, scale: 2
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_quotes_on_product_id"
    t.index ["status"], name: "index_quotes_on_status"
  end

  add_foreign_key "option_groups", "products"
  add_foreign_key "option_values", "option_groups"
  add_foreign_key "quote_items", "option_values"
  add_foreign_key "quote_items", "quotes"
  add_foreign_key "quotes", "products"
end
