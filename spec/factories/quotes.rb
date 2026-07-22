FactoryBot.define do
  factory :quote do
    customer_name { Faker::Name.name }
    customer_email { Faker::Internet.email }
    status { 'draft' }
    total_price { nil }
    configuration_data { {} }
    association :product
  end
end
