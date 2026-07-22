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
    return BigDecimal("0") unless product
    base = product.base_price
    return base unless configuration_data.is_a?(Hash) && configuration_data.present?

    modifiers = configuration_data.sum do |_group_id, value_id|
      OptionValue.where(id: value_id).pick(:price_modifier) || BigDecimal("0")
    end
    base + modifiers
  end

  private

  def configuration_data_must_be_hash
    return if configuration_data.nil? || configuration_data.is_a?(Hash)
    errors.add(:configuration_data, "must be a Hash or nil")
  end
end
