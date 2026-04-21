FactoryBot.define do
  factory :observation_dimension do
    sequence(:name)     { |n| "Dimension #{n}" }
    sequence(:code)     { |n| "D#{n}" }
    category            { "Emotional Support" }
    description         { "A test observation dimension." }
    min_score           { 1 }
    max_score           { 7 }
    sequence(:position) { |n| n }
    active              { true }
  end
end
