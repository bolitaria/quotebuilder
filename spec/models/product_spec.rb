require 'rails_helper'

RSpec.describe Product, type: :model do
  subject(:product) { build(:product) }

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
