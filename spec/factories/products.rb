FactoryBot.define do
  factory :product do
    name { Faker::Commerce.product_name }
    sequence(:code) { |n| "CODE-#{n}" }
    base_price { Faker::Commerce.price(range: 50.0..1000.0) }
    category { %w[Barriers Bollards Rack\ Protectors].sample }
  end
end
