FactoryBot.define do
  factory :student do
    classroom
    first_name { Faker::Name.first_name }
    last_name  { Faker::Name.last_name }
    date_of_birth { Faker::Date.between(from: 12.years.ago, to: 5.years.ago) }
    sequence(:student_id_number) { |n| "S#{n.to_s.rjust(7, '0')}" }
  end
end
