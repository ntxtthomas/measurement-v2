FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password" }
    first_name { Faker::Name.first_name }
    last_name  { Faker::Name.last_name }
    role       { "observer" }
    active     { true }

    trait :admin do
      role { "admin" }
    end
  end
end
