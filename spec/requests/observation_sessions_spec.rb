require "rails_helper"

RSpec.describe "ObservationSessions", type: :request do
  let(:org)       { create(:organization) }
  let(:school)    { create(:school, organization: org) }
  let(:teacher)   { create(:teacher, school: school) }
  let(:classroom) { create(:classroom, school: school, teacher: teacher) }
  let(:user)      { create(:user) }
  let(:observer)  { create(:observer, user: user, organization: org) }

  def sign_in(u = user)
    post login_path, params: { email: u.email, password: "password" }
  end

  describe "GET /observation_sessions" do
    it "redirects to login when not authenticated" do
      get observation_sessions_path
      expect(response).to redirect_to(login_path)
    end

    it "returns 200 when authenticated" do
      sign_in
      get observation_sessions_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /observation_sessions/:id" do
    let(:session) { create(:observation_session, :in_progress, observer: observer, classroom: classroom, teacher: teacher) }

    it "returns 200 for the session show page" do
      # Ensure dimensions exist for completion_rate
      create_list(:observation_dimension, 2)
      sign_in
      get observation_session_path(session)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /observation_sessions" do
    it "creates a session and redirects" do
      sign_in
      expect {
        post observation_sessions_path, params: {
          observation_session: {
            classroom_id: classroom.id,
            teacher_id:   teacher.id,
            observed_on:  Date.today.to_s
          }
        }
      }.to change(ObservationSession, :count).by(1)

      expect(response).to redirect_to(observation_session_path(ObservationSession.last))
    end
  end

  describe "POST /observation_sessions/:id/finalize" do
    let!(:dims) do
      [
        create(:observation_dimension, code: "A1", active: true),
        create(:observation_dimension, code: "A2", active: true)
      ]
    end
    let(:obs_session) { create(:observation_session, :in_progress, observer: observer, classroom: classroom, teacher: teacher) }

    before do
      sign_in
      allow(ObserverMailer).to receive_message_chain(:session_finalized, :deliver_now)
    end

    it "finalizes the session when all scores are provided" do
      score_params = {}
      dims.each { |d| score_params[d.id.to_s] = "5" }

      post finalize_observation_session_path(obs_session), params: { scores: score_params }

      expect(obs_session.reload.status).to eq("finalized")
      expect(response).to redirect_to(observation_session_path(obs_session))
    end

    it "does not allow finalization by a different observer" do
      other_user     = create(:user)
      _other_observer = create(:observer, user: other_user, organization: org)

      sign_in(other_user)
      score_params = {}
      dims.each { |d| score_params[d.id.to_s] = "5" }

      post finalize_observation_session_path(obs_session), params: { scores: score_params }

      expect(obs_session.reload.status).to eq("in_progress")
      expect(response).to redirect_to(observation_sessions_path)
    end
  end
end
