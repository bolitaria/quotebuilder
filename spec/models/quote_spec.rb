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
      let(:product) { create(:product) }

      it 'accepts a Hash' do
        quote = build(:quote, product: product, configuration_data: { '1' => '2' })
        expect(quote).to be_valid
      end

      it 'accepts nil' do
        quote = build(:quote, product: product, configuration_data: nil)
        expect(quote).to be_valid
      end

      it 'rejects non-Hash, non-nil values' do
        quote = build(:quote, product: product, configuration_data: 'invalid')
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
