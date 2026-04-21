FactoryBot.define do
  factory :classroom do
    school
    teacher
    sequence(:name) { |n| "Classroom #{n}" }
    grade_level { %w[K 1st 2nd 3rd 4th 5th].sample }
    subject     { "Math" }
  end
end
