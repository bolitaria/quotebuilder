#!/bin/bash
# Spec 0 – Industrial Product Configurator: Data Model, Migrations, Seeds, Tests
# Project: quotebuilder (Rails 8 + PostgreSQL + Hotwire)

set -e  # detener si hay error

echo "==> Creando directorios necesarios..."
mkdir -p db/migrate spec/models spec/factories spec/system

echo "==> Generando migraciones..."

cat > db/migrate/20260722000001_create_products.rb << 'EOF'
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
EOF

cat > db/migrate/20260722000002_create_option_groups.rb << 'EOF'
class CreateOptionGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :option_groups do |t|
      t.string :name, null: false
      t.references :product, null: false, foreign_key: true
      t.timestamps
    end
  end
end
EOF

cat > db/migrate/20260722000003_create_option_values.rb << 'EOF'
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
EOF

cat > db/migrate/20260722000004_create_quotes.rb << 'EOF'
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
EOF

cat > db/migrate/20260722000005_create_quote_items.rb << 'EOF'
class CreateQuoteItems < ActiveRecord::Migration[8.0]
  def change
    create_table :quote_items do |t|
      t.references :quote, null: false, foreign_key: true
      t.references :option_value, null: false, foreign_key: true
      t.timestamps
    end
  end
end
EOF

echo "==> Generando modelos..."

cat > app/models/product.rb << 'EOF'
class Product < ApplicationRecord
  has_many :option_groups, dependent: :destroy
  has_many :option_values, through: :option_groups
  has_many :quotes, dependent: :restrict_with_error

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true
  validates :base_price, numericality: { greater_than_or_equal_to: 0 }
end
EOF

cat > app/models/option_group.rb << 'EOF'
class OptionGroup < ApplicationRecord
  belongs_to :product
  has_many :option_values, dependent: :destroy
  validates :name, presence: true
end
EOF

cat > app/models/option_value.rb << 'EOF'
class OptionValue < ApplicationRecord
  belongs_to :option_group
  has_many :quote_items, dependent: :nullify
  validates :name, presence: true
  validates :price_modifier, numericality: true
end
EOF

cat > app/models/quote.rb << 'EOF'
class Quote < ApplicationRecord
  belongs_to :product
  has_many :quote_items, dependent: :destroy
  has_many :option_values, through: :quote_items

  validates :customer_name, presence: true
  validates :customer_email, presence: true,
            format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email" }
  validates :status, inclusion: { in: %w[draft completed failed] }
  validates :product_id, presence: true
  validate :configuration_data_must_be_hash

  def total_price
    return BigDecimal('0') unless product
    base = product.base_price
    return base unless configuration_data.is_a?(Hash) && configuration_data.present?

    modifiers = configuration_data.sum do |_group_id, value_id|
      OptionValue.where(id: value_id).pick(:price_modifier) || BigDecimal('0')
    end
    base + modifiers
  end

  private

  def configuration_data_must_be_hash
    return if configuration_data.nil? || configuration_data.is_a?(Hash)
    errors.add(:configuration_data, 'must be a Hash or nil')
  end
end
EOF

cat > app/models/quote_item.rb << 'EOF'
class QuoteItem < ApplicationRecord
  belongs_to :quote
  belongs_to :option_value
  validates :quote, presence: true
  validates :option_value, presence: true
end
EOF

echo "==> Generando seeds..."

cat > db/seeds.rb << 'EOF'
barrier = Product.find_or_create_by!(code: 'BAR-001') do |p|
  p.name = 'Heavy-Duty Barrier'
  p.base_price = 500.00
  p.category = 'Barriers'
end

color_group = OptionGroup.find_or_create_by!(product: barrier, name: 'Color')
OptionValue.find_or_create_by!(option_group: color_group, name: 'Yellow', price_modifier: 0.0)
OptionValue.find_or_create_by!(option_group: color_group, name: 'Red', price_modifier: 20.0)

length_group = OptionGroup.find_or_create_by!(product: barrier, name: 'Length')
OptionValue.find_or_create_by!(option_group: length_group, name: '1m', price_modifier: 0.0)
OptionValue.find_or_create_by!(option_group: length_group, name: '2m', price_modifier: 50.0)
OptionValue.find_or_create_by!(option_group: length_group, name: '3m', price_modifier: 100.0)

bollard = Product.find_or_create_by!(code: 'BOL-002') do |p|
  p.name = 'Steel Bollard'
  p.base_price = 150.00
  p.category = 'Bollards'
end

finish_group = OptionGroup.find_or_create_by!(product: bollard, name: 'Finish')
OptionValue.find_or_create_by!(option_group: finish_group, name: 'Galvanized', price_modifier: 0.0)
OptionValue.find_or_create_by!(option_group: finish_group, name: 'Powder Coated', price_modifier: 30.0)

height_group = OptionGroup.find_or_create_by!(product: bollard, name: 'Height')
OptionValue.find_or_create_by!(option_group: height_group, name: '1m', price_modifier: 0.0)
OptionValue.find_or_create_by!(option_group: height_group, name: '1.5m', price_modifier: 40.0)

rack_guard = Product.find_or_create_by!(code: 'RACK-003') do |p|
  p.name = 'Rack Guard'
  p.base_price = 200.00
  p.category = 'Rack Protectors'
end

material_group = OptionGroup.find_or_create_by!(product: rack_guard, name: 'Material')
OptionValue.find_or_create_by!(option_group: material_group, name: 'Steel', price_modifier: 0.0)
OptionValue.find_or_create_by!(option_group: material_group, name: 'Polymer', price_modifier: 15.0)

rack_color_group = OptionGroup.find_or_create_by!(product: rack_guard, name: 'Color')
OptionValue.find_or_create_by!(option_group: rack_color_group, name: 'Yellow', price_modifier: 0.0)
OptionValue.find_or_create_by!(option_group: rack_color_group, name: 'Grey', price_modifier: 5.0)

puts "Seeded #{Product.count} products, #{OptionGroup.count} option groups, #{OptionValue.count} option values."
EOF

echo "==> Generando factories..."

cat > spec/factories/products.rb << 'EOF'
FactoryBot.define do
  factory :product do
    name { Faker::Commerce.product_name }
    sequence(:code) { |n| "CODE-#{n}" }
    base_price { Faker::Commerce.price(range: 50.0..1000.0) }
    category { %w[Barriers Bollards Rack\ Protectors].sample }
  end
end
EOF

cat > spec/factories/option_groups.rb << 'EOF'
FactoryBot.define do
  factory :option_group do
    name { Faker::Commerce.department(max: 10) }
    association :product
  end
end
EOF

cat > spec/factories/option_values.rb << 'EOF'
FactoryBot.define do
  factory :option_value do
    name { Faker::Commerce.material }
    price_modifier { Faker::Commerce.price(range: -10.0..50.0) }
    association :option_group
  end
end
EOF

cat > spec/factories/quotes.rb << 'EOF'
FactoryBot.define do
  factory :quote do
    customer_name { Faker::Name.name }
    customer_email { Faker::Internet.email }
    status { 'draft' }
    total_price { nil }
    configuration_data { {} }
    association :product
  end
end
EOF

cat > spec/factories/quote_items.rb << 'EOF'
FactoryBot.define do
  factory :quote_item do
    association :quote
    association :option_value
  end
end
EOF

echo "==> Generando tests de modelo..."

cat > spec/models/product_spec.rb << 'EOF'
require 'rails_helper'

RSpec.describe Product, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:code) }
    it { should validate_uniqueness_of(:code) }
    it { should validate_numericality_of(:base_price).is_greater_than_or_equal_to(0) }
  end

  describe 'associations' do
    it { should have_many(:option_groups).dependent(:destroy) }
    it { should have_many(:option_values).through(:option_groups) }
    it { should have_many(:quotes).dependent(:restrict_with_error) }
  end
end
EOF

cat > spec/models/quote_spec.rb << 'EOF'
require 'rails_helper'

RSpec.describe Quote, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:customer_name) }
    it { should validate_presence_of(:customer_email) }
    it { should allow_value('test@example.com').for(:customer_email) }
    it { should_not allow_value('invalid-email').for(:customer_email) }
    it { should validate_inclusion_of(:status).in_array(%w[draft completed failed]) }
    it { should validate_presence_of(:product_id) }

    describe 'configuration_data' do
      it 'accepts a Hash' do
        quote = build(:quote, configuration_data: { '1' => '2' })
        expect(quote).to be_valid
      end
      it 'accepts nil' do
        quote = build(:quote, configuration_data: nil)
        expect(quote).to be_valid
      end
      it 'rejects non-Hash, non-nil values' do
        quote = build(:quote, configuration_data: 'invalid')
        expect(quote).not_to be_valid
        expect(quote.errors[:configuration_data]).to include('must be a Hash or nil')
      end
    end
  end

  describe 'associations' do
    it { should belong_to(:product) }
    it { should have_many(:quote_items).dependent(:destroy) }
    it { should have_many(:option_values).through(:quote_items) }
  end

  describe '#total_price' do
    let(:product) { create(:product, base_price: 100.0) }
    let(:option_group) { create(:option_group, product: product) }
    let(:option_value1) { create(:option_value, option_group: option_group, price_modifier: 10.0) }
    let(:option_value2) { create(:option_value, option_group: option_group, price_modifier: 20.0) }

    it 'returns 0 when no product' do
      quote = build(:quote, product: nil)
      expect(quote.total_price).to eq(BigDecimal('0'))
    end
    it 'returns base price when empty config' do
      quote = build(:quote, product: product, configuration_data: {})
      expect(quote.total_price).to eq(product.base_price)
    end
    it 'adds modifiers' do
      config = { option_group.id.to_s => option_value1.id.to_s }
      quote = build(:quote, product: product, configuration_data: config)
      expect(quote.total_price).to eq(BigDecimal('110.0'))
    end
    it 'ignores stale option IDs' do
      config = { option_group.id.to_s => '999999' }
      quote = build(:quote, product: product, configuration_data: config)
      expect(quote.total_price).to eq(product.base_price)
    end
    it 'returns base when config nil' do
      quote = build(:quote, product: product, configuration_data: nil)
      expect(quote.total_price).to eq(product.base_price)
    end
    it 'sums multiple groups' do
      another_group = create(:option_group, product: product)
      another_value = create(:option_value, option_group: another_group, price_modifier: 5.0)
      config = { option_group.id.to_s => option_value1.id.to_s, another_group.id.to_s => another_value.id.to_s }
      quote = build(:quote, product: product, configuration_data: config)
      expect(quote.total_price).to eq(BigDecimal('115.0'))
    end
  end
end
EOF

cat > spec/models/option_value_spec.rb << 'EOF'
require 'rails_helper'

RSpec.describe OptionValue, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_numericality_of(:price_modifier) }
  end
  describe 'associations' do
    it { should belong_to(:option_group) }
    it { should have_many(:quote_items).dependent(:nullify) }
  end
end
EOF

cat > spec/models/quote_item_spec.rb << 'EOF'
require 'rails_helper'

RSpec.describe QuoteItem, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:quote) }
    it { should validate_presence_of(:option_value) }
  end
  describe 'associations' do
    it { should belong_to(:quote) }
    it { should belong_to(:option_value) }
  end
end
EOF

echo "==> Generando system spec placeholder..."

cat > spec/system/placeholder_spec.rb << 'EOF'
require 'rails_helper'

RSpec.describe 'Application boot', type: :system do
  it 'loads the root page without errors' do
    visit root_path
    expect(page.status_code).to eq(200)
  end
end
EOF

echo ""
echo "✅ Spec 0 generada correctamente."
echo "👉 Ahora ejecuta manualmente:"
echo "   rails db:create db:migrate db:seed"
echo "   bundle exec rspec"
