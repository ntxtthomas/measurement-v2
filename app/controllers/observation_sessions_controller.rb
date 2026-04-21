# =============================================================================
# ObservationSessionsController
#
# DELIBERATE HOTSPOT: The `finalize` action is too long and does too much inline.
#
# Problems:
#  - Row-by-row score upsert (should be bulk / transactional)
#  - Authorization check is inline, not in a policy object
#  - Calls session.finalize! which does even more (see ObservationSession model)
#  - No protection against double-submit (two requests can race)
#
# IMPROVEMENT PATH:
#  - Extract score writes to a service: ObservationScoreWriter.call(session, params)
#  - Extract authorization to a policy: ObservationSessionPolicy
#  - Move finalize! work to a proper service or Sidekiq job
#  - Add an optimistic lock or status guard against double-submit race
# =============================================================================
class ObservationSessionsController < ApplicationController
  before_action :set_session, only: [:show, :edit, :update, :destroy, :finalize_form, :finalize]

  def index
    # SMELL: No pagination — loads all sessions for current observer
    @sessions = ObservationSession
                  .where(observer: current_observer)
                  .order(observed_on: :desc)
  end

  def show
    @dimensions = ObservationDimension.active.ordered
    @scores_by_dimension = @session.observation_scores.index_by(&:observation_dimension_id)
    @notes = @session.observation_notes.order(:created_at)
    # SMELL: @notes renders students per note in the view — N+1
  end

  def new
    @session  = ObservationSession.new
    @classrooms  = Classroom.all.order(:name)           # SMELL: loads everything, no scoping
    @teachers    = Teacher.all.order(:last_name)        # SMELL: loads everything
    @dimensions  = ObservationDimension.active.ordered
  end

  def create
    @session = ObservationSession.new(session_params)
    @session.observer = current_observer
    @session.status   = :in_progress

    if @session.save
      redirect_to @session, notice: "Observation session started."
    else
      @classrooms = Classroom.all.order(:name)
      @teachers   = Teacher.all.order(:last_name)
      @dimensions = ObservationDimension.active.ordered
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @classrooms = Classroom.all.order(:name)
    @teachers   = Teacher.all.order(:last_name)
  end

  def update
    if @session.update(session_params)
      redirect_to @session, notice: "Session updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @session.destroy
    redirect_to observation_sessions_path, notice: "Session deleted."
  end

  def finalize_form
    @dimensions = ObservationDimension.active.ordered
    @scores_by_dimension = @session.observation_scores.index_by(&:observation_dimension_id)
    @students = @session.classroom.students.order(:last_name, :first_name)
  end

  # DELIBERATE FAT ACTION:
  # Handles score upsert (row-by-row), note association, and finalization all inline.
  def finalize
    # SMELL: Inline authorization instead of a policy/pundit check
    unless owned_by_current_observer? || current_user.admin?
      return redirect_to observation_sessions_path, alert: "Not authorized to finalize this session."
    end

    # SMELL: Row-by-row score upsert.
    # At 8 dimensions this is 8 × (SELECT + INSERT/UPDATE) = 16 queries.
    # Should be: upsert_all or a single transaction with one INSERT ... ON CONFLICT.
    if params[:scores].present?
      params[:scores].each do |dimension_id, score_value|
        score = ObservationScore.find_or_initialize_by(
          observation_session_id:   @session.id,
          observation_dimension_id: dimension_id.to_i
        )
        score.score = score_value.to_i
        # SMELL: No transaction around the loop — partial saves possible on error
        unless score.save
          flash[:alert] = "Score save failed for dimension #{dimension_id}: #{score.errors.full_messages.join(', ')}"
          return render :finalize_form, status: :unprocessable_entity
        end
      end
    end

    # SMELL: Note creation also row-by-row with optional student tagging
    if params[:notes].present?
      params[:notes].each do |note_params|
        next if note_params[:content].to_s.strip.empty?

        note = ObservationNote.create!(
          observation_session: @session,
          observer:            current_observer,
          content:             note_params[:content]
        )

        # SMELL: N+1 for assigning students — could use insert_all
        Array(note_params[:student_ids]).compact.each do |sid|
          ObservationNoteStudent.create!(observation_note: note, student_id: sid.to_i)
        end
      end
    end

    # SMELL: finalize! itself does even more work (see ObservationSession model)
    if @session.finalize!(current_user)
      redirect_to observation_session_path(@session), notice: "Session finalized successfully."
    else
      flash[:alert] = @session.errors.full_messages.join(", ")
      @dimensions  = ObservationDimension.active.ordered
      @scores_by_dimension = @session.observation_scores.index_by(&:observation_dimension_id)
      @students = @session.classroom.students.order(:last_name)
      render :finalize_form, status: :unprocessable_entity
    end
  end

  private

  def set_session
    @session = ObservationSession.find(params[:id])
  end

  def session_params
    params.require(:observation_session).permit(:classroom_id, :teacher_id, :observed_on)
  end

  # SMELL: Authorization check is a private method in the controller rather than
  # a dedicated policy class. Duplicated (or slightly different) across controllers.
  def owned_by_current_observer?
    @session.observer_id == current_observer&.id
  end
end
