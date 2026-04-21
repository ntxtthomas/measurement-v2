FactoryBot.define do
  factory :observer do
    user
    organization
    certification_level { "standard" }
    certified_on        { 1.year.ago }
    active              { true }
  end
end
