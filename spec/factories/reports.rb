FactoryBot.define do
  factory :report do
    observation_session
    generated_by { 1 }
    status       { :complete }
    content      { { generated_at: Time.current.iso8601, overall_average: 4.5 }.to_json }
  end
end
