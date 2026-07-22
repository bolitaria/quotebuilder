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
