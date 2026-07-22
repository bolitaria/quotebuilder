FactoryBot.define do
  factory :option_group do
    name { Faker::Commerce.department(max: 10) }
    association :product
  end
end
