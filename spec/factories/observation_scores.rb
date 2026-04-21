FactoryBot.define do
  factory :observation_score do
    observation_session
    observation_dimension
    score { rand(1..7) }
  end
end
