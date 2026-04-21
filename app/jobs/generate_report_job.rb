# =============================================================================
# GenerateReportJob
#
# DELIBERATE HOTSPOT: Non-idempotent background job.
#
# Problems:
#  1. No guard against duplicate reports — if the job runs twice (retry, manual
#     trigger, or race condition) it creates two Report rows for the same session.
#  2. N+1 loops inside build_content: score.observation_dimension loaded per score.
#  3. Note-student chain: note.students.map — N+1 per note.
#  4. re-raises after marking the report failed, so Sidekiq will retry it,
#     creating yet another Report row in the :generating state.
#  5. Magic number score classification duplicated from ObservationSession model.
#
# IMPROVEMENT PATH:
#  - Add: return if Report.complete.exists?(observation_session: session)
#  - Use eager loading: session.observation_scores.includes(:observation_dimension)
#  - Use: session.observation_notes.includes(:students)
#  - Extract score classification to a shared module/value object
#  - Add a unique index on (observation_session_id) for reports if only one is desired
# =============================================================================
class GenerateReportJob < ApplicationJob
  queue_as :reports

  def perform(observation_session_id)
    session = ObservationSession.find(observation_session_id)

    # SMELL: No idempotency guard. If this job runs twice, two reports are created.
    # Fix: uncomment the line below (and handle status transition properly)
    # return if Report.where(observation_session: session, status: [:complete, :generating]).exists?

    report = Report.create!(
      observation_session: session,
      generated_by:        session.observer.user.id,
      status:              :generating
    )

    content = build_content(session)
    report.update!(status: :complete, content: content)
  rescue ActiveRecord::RecordNotFound => e
    # Session deleted before job ran — safe to discard
    Rails.logger.warn "[GenerateReportJob] Session #{observation_session_id} not found: #{e.message}"
  rescue StandardError => e
    # SMELL: marks the report failed but then re-raises, triggering retry.
    # Retry creates ANOTHER Report row in :generating state.
    report&.update(status: :failed, error_message: e.message)
    raise e
  end

  private

  def build_content(session)
    # SMELL: N+1 — calls score.observation_dimension.name for each score
    scores = session.observation_scores.map do |score|
      {
        dimension: score.observation_dimension.name, # N+1 — no eager load
        code:      score.observation_dimension.code,  # N+1 again
        score:     score.score,
        level:     classify_score(score.score)
      }
    end

    # SMELL: N+1 — note.students resolves for each note
    notes = session.observation_notes.map do |note|
      {
        content:  note.content,
        students: note.students.map { |s| s.full_name } # N+1 per note
      }
    end

    {
      generated_at:   Time.current.iso8601,
      scores:         scores,
      notes:          notes,
      overall_average: session.average_score,
      # SMELL: Law of Demeter — reaching through 3 associations
      organization:   session.classroom.school.organization.name,
      school:         session.classroom.school.name
    }.to_json
  end

  # SMELL: Magic number classification duplicated from:
  #  - ObservationSession#classify_score
  #  - ObservationHelper#display_score_level
  # Three independent implementations with subtly different behavior is a DRY violation.
  def classify_score(score)
    if score <= 2
      "Concern"
    elsif score <= 5
      "Mixed"
    else
      "Strong"
    end
  end
end
