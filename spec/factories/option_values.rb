FactoryBot.define do
  factory :option_value do
    name { Faker::Commerce.material }
    price_modifier { Faker::Commerce.price(range: -10.0..50.0) }
    association :option_group
  end
end
