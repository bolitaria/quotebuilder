class QuoteItem < ApplicationRecord
  belongs_to :quote
  belongs_to :option_value
  validates :quote, presence: true
  validates :option_value, presence: true
end
