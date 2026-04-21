FactoryBot.define do
  factory :teacher do
    school
    first_name { Faker::Name.first_name }
    last_name  { Faker::Name.last_name }
    sequence(:email) { |n| "teacher#{n}@example.com" }
    total_sessions       { 0 }
    average_score_cache  { nil }
  end
end
