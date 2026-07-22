class OptionValue < ApplicationRecord
  belongs_to :option_group
  has_many :quote_items, dependent: :nullify
  validates :name, presence: true
  validates :price_modifier, numericality: true
end
