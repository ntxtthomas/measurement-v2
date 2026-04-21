# =============================================================================
# ObservationSession — the core event model
#
# DELIBERATE HOTSPOT: This model is intentionally fat.
#   - finalize! does too much in a single method
#   - Callback chain couples lifecycle to side effects
#   - Law of Demeter violations throughout
#   - average_score calculated multiple ways
#   - Magic numbers (1-7 score range) repeated
#   - Notes on each smell are inline; use them as refactoring starting points.
#
# Bloodhound questions to ask here:
#   Q3: Is too much going on in one spot?          → Yes, finalize!
#   Q6: Is it hard to change?                     → Yes, due to callbacks
#   Q7: Is it brutally imperative?                → Yes, build_report_content
#   Q12: What code smells are present?             → see inline comments
# =============================================================================
class ObservationSession < ApplicationRecord
  belongs_to :observer
  belongs_to :classroom
  belongs_to :teacher

  has_many :observation_scores,     dependent: :destroy
  has_many :observation_notes,      dependent: :destroy
  has_many :reports,                dependent: :destroy
  has_many :observation_dimensions, through: :observation_scores

  enum status: { draft: 0, in_progress: 1, finalized: 2, cancelled: 3 }

  validates :observed_on,  presence: true
  validates :observer_id,  presence: true
  validates :classroom_id, presence: true
  validates :teacher_id,   presence: true

  # ── Callback chain ─────────────────────────────────────────────────────────
  # SMELL: These after_save callbacks fire on EVERY save, not just on finalization.
  # recalculate_teacher_session_count will run even on a trivial notes_count_cache update.
  # This is a classic performance and coupling problem.
  after_save :update_classroom_last_observed,    if: :finalized?
  after_save :recalculate_teacher_session_count  # runs on every save — intentional flaw

  scope :recent,    -> { order(observed_on: :desc) }
  scope :this_week, -> { where(observed_on: Time.current.beginning_of_week..Time.current.end_of_week) }
  # SMELL: No scope for :finalized — callers write where(status: :finalized) everywhere

  # ── Public interface ───────────────────────────────────────────────────────

  # SMELL: Long method (80+ lines). Does state check, score validation,
  # report generation, notification, and teacher stat update all inline.
  # SRP violation — at minimum the report generation and notification belong elsewhere.
  # IDEAL candidate to extract: FinalizeObservationSession service object.
  def finalize!(current_user)
    return false unless in_progress?

    # SMELL: Imperative guard instead of a proper state machine
    if finalized?
      errors.add(:base, "Session has already been finalized")
      return false
    end

    # SMELL: Loading all active dimensions via a class-level query inside an instance method
    expected_count = ObservationDimension.where(active: true).count
    actual_count   = observation_scores.count

    if actual_count < expected_count
      missing_count = expected_count - actual_count
      errors.add(:base, "#{missing_count} dimension score(s) are missing")
      return false
    end

    # SMELL: Row-by-row validation instead of a DB constraint or a single query check
    observation_scores.each do |score|
      dim = ObservationDimension.find(score.observation_dimension_id) # N+1
      unless score.score.between?(dim.min_score, dim.max_score)
        errors.add(:base, "Score for #{dim.name} is out of range (#{dim.min_score}–#{dim.max_score})")
        return false
      end
    end

    # SMELL: Setting attributes individually
    self.status         = :finalized
    self.finalized_at   = Time.current
    self.finalized_by_id = current_user.id
    self.notes_count_cache = observation_notes.count  # manual cache — will drift on note deletion

    save!

    # SMELL: Synchronous report generation inside finalize!
    # This blocks the request. Should be GenerateReportJob.perform_later(id)
    _report = generate_report_synchronously!(current_user)

    # SMELL: Synchronous email. deliver_now blocks. Use deliver_later.
    begin
      ObserverMailer.session_finalized(self).deliver_now
    rescue StandardError => e
      # SMELL: Silent swallow — no alerting, no retry, caller never knows
      Rails.logger.error "[ObservationSession#finalize!] Mailer failed: #{e.message}"
    end

    update_teacher_stats!

    true
  rescue ActiveRecord::RecordInvalid => e
    errors.add(:base, e.message)
    false
  end

  # SMELL: Duplicate of average_score below; called from views as session.overall_average
  def overall_average
    scores = observation_scores.to_a
    return nil if scores.empty?

    scores.map(&:score).sum.to_f / scores.size
  end

  # SMELL: also calculates average but uses SQL aggregation — two implementations exist
  def average_score
    return nil if observation_scores.empty?

    observation_scores.average(:score)&.to_f
  end

  def score_for(dimension_code)
    observation_scores
      .joins(:observation_dimension)
      .find_by(observation_dimensions: { code: dimension_code })
      &.score
  end

  def completion_rate
    total = ObservationDimension.where(active: true).count # class query in instance method
    return 0 if total.zero?

    (observation_scores.count.to_f / total * 100).round
  end

  def can_finalize?
    in_progress? && completion_rate == 100
  end

  # SMELL: Law of Demeter — instance method chains through 3 associations
  def organization_name
    classroom.school.organization.name
  end

  def school_name
    classroom.school.name
  end

  # SMELL: Rescuing NoMethodError to handle a nil association is fragile.
  # The right fix is to ensure teacher is always present or use Optional safely.
  def teacher_full_name
    teacher.full_name
  rescue NoMethodError
    "Unknown Teacher"
  end

  # ── Private ────────────────────────────────────────────────────────────────
  private

  # SMELL: Called on every after_save, not just finalization.
  # At scale with many concurrent session updates this becomes a hot path.
  def recalculate_teacher_session_count
    # SMELL: Loading all finalized sessions to count when .count query is enough
    finalized_sessions = teacher.observation_sessions.where(status: :finalized)
    teacher.update_columns(total_sessions: finalized_sessions.count)
  end

  def update_classroom_last_observed
    classroom.update_column(:last_observed_at, finalized_at || updated_at)
  end

  # SMELL: Long method. Mixes data gathering, formatting, and structure building.
  # Contains multiple N+1 loops and Law of Demeter chains.
  def build_report_content
    # SMELL: Law of Demeter
    org    = classroom.school.organization
    school = classroom.school

    session_info = {
      observer_name: "#{observer.user.first_name} #{observer.user.last_name}", # LoD
      classroom:     classroom.name,
      teacher:       teacher_full_name,
      school:        school.name,
      organization:  org.name,
      date:          observed_on.strftime("%B %d, %Y"),
      duration:      "N/A" # SMELL: duration is not tracked — placeholder left forever
    }

    # SMELL: N+1 inside loop — calls ObservationDimension.find for each score
    scores_by_dimension = {}
    observation_scores.each do |score|
      dim = ObservationDimension.find(score.observation_dimension_id) # N+1
      scores_by_dimension[dim.code] = {
        name:  dim.name,
        score: score.score,
        min:   dim.min_score,
        max:   dim.max_score,
        level: classify_score(score.score) # magic number logic below
      }
    end

    # SMELL: Category averages computed in a second N+1 loop (dim loaded again)
    category_averages = {}
    ObservationDimension.active.pluck(:category).uniq.each do |category|
      cat_scores = []
      observation_scores.each do |score|
        dim = ObservationDimension.find(score.observation_dimension_id) # N+1 again
        cat_scores << score.score if dim.category == category
      end
      category_averages[category] = cat_scores.empty? ? nil : (cat_scores.sum.to_f / cat_scores.size).round(2)
    end

    # SMELL: N+1 for student-linked note check
    student_linked_count = 0
    observation_notes.each do |note|
      student_linked_count += 1 if note.students.any? # N+1
    end

    {
      session:           session_info,
      scores:            scores_by_dimension,
      category_averages: category_averages,
      overall_average:   average_score,
      context:           {
        student_count:            classroom.students.count,
        note_count:               observation_notes.count,
        student_linked_note_count: student_linked_count
      }
    }.to_json
  end

  # SMELL: Magic numbers for score classification duplicated here AND in
  # GenerateReportJob AND in ObservationHelper. Three places, three slight variations.
  def classify_score(score)
    if score <= 2
      "Concern"
    elsif score <= 5
      "Mixed"
    else
      "Strong"
    end
  end

  def generate_report_synchronously!(current_user)
    # SMELL: No guard against duplicate report — if called twice, two Report rows are created.
    # This matches the same non-idempotency bug in GenerateReportJob.
    report = Report.create!(
      observation_session: self,
      generated_by:        current_user.id,
      status:              :generating
    )

    content = build_report_content
    report.update!(status: :complete, content: content)
    report
  rescue StandardError => e
    Rails.logger.error "[ObservationSession] Report generation failed: #{e.message}"
    report&.update(status: :failed, error_message: e.message)
    nil
  end

  def update_teacher_stats!
    # SMELL: Loading all finalized sessions into Ruby to compute average
    # instead of using GROUP BY / AVG in SQL.
    finalized = teacher.observation_sessions.where(status: :finalized).to_a
    avg = finalized.map(&:average_score).compact
    computed_avg = avg.empty? ? nil : (avg.sum / avg.size).round(2)

    teacher.update!(
      total_sessions:      finalized.count,
      average_score_cache: computed_avg
    )
  end
end
