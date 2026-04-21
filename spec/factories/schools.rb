FactoryBot.define do
  factory :school do
    organization
    sequence(:name) { |n| "School #{n}" }
    city   { Faker::Address.city }
    state  { Faker::Address.state_abbr }
    status { "active" }
  end
end
