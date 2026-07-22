FactoryBot.define do
  factory :quote_item do
    association :quote
    association :option_value
  end
end
