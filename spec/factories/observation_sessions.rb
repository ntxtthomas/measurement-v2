FactoryBot.define do
  factory :observation_session do
    observer
    classroom
    teacher  { classroom.teacher || association(:teacher, school: classroom.school) }
    observed_on { Date.today }
    status      { :draft }

    trait :in_progress do
      status { :in_progress }
    end

    trait :finalized do
      status          { :finalized }
      finalized_at    { Time.current }
      finalized_by_id { 1 }
    end

    trait :with_scores do
      after(:create) do |session|
        dims = ObservationDimension.active.ordered
        dims.each do |dim|
          create(:observation_score, observation_session: session, observation_dimension: dim, score: rand(3..6))
        end
      end
    end
  end
end
