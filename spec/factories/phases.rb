FactoryBot.define do
  factory :phase do
    sequence(:name)     { |n| "Phase #{n}" }
    description         { "A test engineering phase." }
    sequence(:position) { |n| n }
    color               { "#6366f1" }
  end
end

FactoryBot.define do
  factory :epic do
    phase
    sequence(:name)     { |n| "Epic #{n}" }
    sequence(:position) { |n| n }
  end
end

FactoryBot.define do
  factory :story do
    epic
    sequence(:name)     { |n| "Story #{n}" }
    sequence(:position) { |n| n }
  end
end

FactoryBot.define do
  factory :task do
    story
    sequence(:name)     { |n| "Task #{n}" }
    status              { :not_started }
    sequence(:position) { |n| n }
  end
end
