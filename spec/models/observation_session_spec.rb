require "rails_helper"

RSpec.describe ObservationSession, type: :model do
  let(:org)       { create(:organization) }
  let(:school)    { create(:school, organization: org) }
  let(:teacher)   { create(:teacher, school: school) }
  let(:classroom) { create(:classroom, school: school, teacher: teacher) }
  let(:user)      { create(:user) }
  let(:observer)  { create(:observer, user: user, organization: org) }

  # Seed the canonical 8 dimensions before finalization specs
  def create_dimensions
    [
      ["Learning Climate",       "LC", "Emotional Support",     1],
      ["Behavioral Guidance",    "BG", "Emotional Support",     2],
      ["Student Engagement",     "SE", "Classroom Organization",3],
      ["Learning Facilitation",  "LF", "Classroom Organization",4],
      ["Instructional Dialogue", "ID", "Instructional Support", 5],
      ["Content Understanding",  "CU", "Instructional Support", 6],
      ["Critical Inquiry",       "CI", "Instructional Support", 7],
      ["Feedback Loops",         "FL", "Instructional Support", 8],
    ].map do |name, code, category, pos|
      ObservationDimension.create!(name: name, code: code, category: category,
                                    position: pos, min_score: 1, max_score: 7, active: true)
    end
  end

  # ── Associations ────────────────────────────────────────────────────────────
  describe "associations" do
    it { should belong_to(:observer) }
    it { should belong_to(:classroom) }
    it { should belong_to(:teacher) }
    it { should have_many(:observation_scores).dependent(:destroy) }
    it { should have_many(:observation_notes).dependent(:destroy) }
    it { should have_many(:reports).dependent(:destroy) }
  end

  # ── Validations ─────────────────────────────────────────────────────────────
  describe "validations" do
    it { should validate_presence_of(:observed_on) }
    it { should validate_presence_of(:observer_id) }
    it { should validate_presence_of(:classroom_id) }
    it { should validate_presence_of(:teacher_id) }
  end

  # ── finalize! ───────────────────────────────────────────────────────────────
  describe "#finalize!" do
    let(:session) { create(:observation_session, :in_progress, observer: observer, classroom: classroom, teacher: teacher) }

    context "with all dimension scores present" do
      before do
        dims = create_dimensions
        dims.each { |d| create(:observation_score, observation_session: session, observation_dimension: d, score: 4) }
        allow(ObserverMailer).to receive_message_chain(:session_finalized, :deliver_now)
      end

      it "transitions status to finalized" do
        expect { session.finalize!(user) }.to change { session.status }.from("in_progress").to("finalized")
      end

      it "sets finalized_at" do
        session.finalize!(user)
        expect(session.finalized_at).to be_present
      end

      it "creates a Report record" do
        expect { session.finalize!(user) }.to change(Report, :count).by(1)
      end

      it "returns true" do
        result = session.finalize!(user)
        expect(result).to be true
      end
    end

    context "when session is not in_progress" do
      let(:session) { create(:observation_session, :finalized, observer: observer, classroom: classroom, teacher: teacher) }

      it "returns false without changing status" do
        result = session.finalize!(user)
        expect(result).to be false
      end
    end

    context "when some dimension scores are missing" do
      before do
        dims = create_dimensions
        # Only add scores for 6 of 8 dimensions
        dims.first(6).each { |d| create(:observation_score, observation_session: session, observation_dimension: d, score: 4) }
      end

      it "returns false and adds an error" do
        result = session.finalize!(user)
        expect(result).to be false
        expect(session.errors[:base]).to be_present
      end

      it "does not change the status" do
        expect { session.finalize!(user) }.not_to change { session.reload.status }
      end
    end
  end

  # ── average_score ──────────────────────────────────────────────────────────
  describe "#average_score" do
    let(:session) { create(:observation_session, observer: observer, classroom: classroom, teacher: teacher) }
    let(:dim_a)   { create(:observation_dimension, code: "TA") }
    let(:dim_b)   { create(:observation_dimension, code: "TB") }

    it "returns nil when no scores exist" do
      expect(session.average_score).to be_nil
    end

    it "returns the average of all scores" do
      create(:observation_score, observation_session: session, observation_dimension: dim_a, score: 4)
      create(:observation_score, observation_session: session, observation_dimension: dim_b, score: 6)
      expect(session.average_score).to eq(5.0)
    end

    # NOTE: This test exists to catch the DRY violation.
    # If average_score and overall_average diverge in implementation,
    # this spec should catch it.
    it "returns the same value as overall_average" do
      create(:observation_score, observation_session: session, observation_dimension: dim_a, score: 3)
      create(:observation_score, observation_session: session, observation_dimension: dim_b, score: 5)
      expect(session.average_score.round(4)).to eq(session.overall_average.round(4))
    end
  end

  # ── completion_rate ────────────────────────────────────────────────────────
  describe "#completion_rate" do
    let(:session) { create(:observation_session, observer: observer, classroom: classroom, teacher: teacher) }

    before { create_dimensions }

    it "returns 0 when no scores recorded" do
      expect(session.completion_rate).to eq(0)
    end

    it "returns 100 when all dimension scores are present" do
      ObservationDimension.active.each do |dim|
        create(:observation_score, observation_session: session, observation_dimension: dim, score: 4)
      end
      expect(session.completion_rate).to eq(100)
    end

    it "returns a partial percentage" do
      ObservationDimension.active.first(4).each do |dim|
        create(:observation_score, observation_session: session, observation_dimension: dim, score: 4)
      end
      expect(session.completion_rate).to eq(50)
    end
  end

  # ── Hotspot callout ────────────────────────────────────────────────────────
  # These tests are intended as regression guards before refactoring.
  # They document existing behavior, not ideal behavior.
  describe "known hotspots (documented, not yet fixed)" do
    it "creates a Report synchronously during finalize! (should be async — see Task: Move report to Sidekiq)" do
      session = create(:observation_session, :in_progress, observer: observer, classroom: classroom, teacher: teacher)
      dims = create_dimensions
      dims.each { |d| create(:observation_score, observation_session: session, observation_dimension: d, score: 4) }
      allow(ObserverMailer).to receive_message_chain(:session_finalized, :deliver_now)

      # This runs synchronously during the request cycle — it is a known performance issue.
      expect { session.finalize!(user) }.to change(Report, :count).by(1)
    end
  end
end
