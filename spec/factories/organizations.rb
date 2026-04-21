FactoryBot.define do
  factory :organization do
    sequence(:name) { |n| "Organization #{n}" }
    sequence(:slug) { |n| "organization-#{n}" }
    contact_email { Faker::Internet.email }
    status { "active" }
  end
end
