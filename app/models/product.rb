class Product < ApplicationRecord
  has_many :option_groups, dependent: :destroy
  has_many :option_values, through: :option_groups
  has_many :quotes, dependent: :restrict_with_error

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true
  validates :base_price, numericality: { greater_than_or_equal_to: 0 }
end
