require "rails_helper"

RSpec.describe Report, type: :model do
  let(:org)       { create(:organization) }
  let(:school)    { create(:school, organization: org) }
  let(:teacher)   { create(:teacher, school: school) }
  let(:classroom) { create(:classroom, school: school, teacher: teacher) }
  let(:user)      { create(:user) }
  let(:observer)  { create(:observer, user: user, organization: org) }
  let(:session)   { create(:observation_session, :finalized, observer: observer, classroom: classroom, teacher: teacher) }

  describe "associations" do
    it { should belong_to(:observation_session) }
  end

  describe "validations" do
    it { should validate_presence_of(:generated_by) }
  end

  describe "#parsed_content" do
    it "returns nil when content is blank" do
      report = create(:report, observation_session: session, content: nil)
      expect(report.parsed_content).to be_nil
    end

    it "parses valid JSON content" do
      data = { overall_average: 4.5, scores: [] }
      report = create(:report, observation_session: session, content: data.to_json)
      expect(report.parsed_content["overall_average"]).to eq(4.5)
    end

    it "returns nil and does not raise for malformed JSON" do
      report = create(:report, observation_session: session, content: "not json {{{")
      expect(report.parsed_content).to be_nil
    end
  end

  describe "status transitions" do
    it "starts as pending by default" do
      report = build(:report, observation_session: session, status: :pending)
      expect(report).to be_pending
    end

    it "can be marked failed" do
      report = create(:report, observation_session: session, status: :failed, error_message: "boom")
      expect(report).to be_failed
      expect(report.error_message).to eq("boom")
    end
  end

  # ── Non-idempotency callout ────────────────────────────────────────────────
  # This spec documents the known problem: multiple reports can exist for one session.
  # After fixing GenerateReportJob idempotency, add a unique index and update this spec.
  describe "duplicate report concern (intentional flaw)" do
    it "allows multiple Report rows for the same session (no unique constraint — known issue)" do
      create(:report, observation_session: session)
      duplicate = Report.new(observation_session: session, generated_by: 1, status: :complete)
      expect(duplicate).to be_valid
      # TODO: After adding unique index + idempotency fix, this should raise
    end
  end
end
