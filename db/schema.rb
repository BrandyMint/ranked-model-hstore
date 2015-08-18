ActiveRecord::Schema.define(version: 20150817210601) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "hstore"
  enable_extension "intarray"

  create_table "products", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.integer  "categories_ids",        default: [],        null: false, array: true
    t.hstore   "category_positions",    default: {},        null: false
  end

  add_index "products", ["categories_ids"], name: "index_products_on_categories_ids", using: :gin
  add_index "products", ["category_positions"], name: "index_products_on_category_positions", using: :gin
end
