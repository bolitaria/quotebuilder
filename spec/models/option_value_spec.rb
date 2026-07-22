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
