class ObservationNotesController < ApplicationController
  before_action :set_session

  def create
    @note = @session.observation_notes.build(note_params)
    @note.observer = current_observer

    if @note.save
      # Attach students if provided
      Array(params[:student_ids]).compact.each do |sid|
        @note.students << Student.find(sid) rescue nil
      end
      redirect_to observation_session_path(@session), notice: "Note added."
    else
      redirect_to observation_session_path(@session), alert: @note.errors.full_messages.join(", ")
    end
  end

  def update
    @note = ObservationNote.find(params[:id])

    if @note.update(note_params)
      redirect_to observation_session_path(@session), notice: "Note updated."
    else
      redirect_to observation_session_path(@session), alert: @note.errors.full_messages.join(", ")
    end
  end

  def destroy
    @note = ObservationNote.find(params[:id])
    @note.destroy
    redirect_to observation_session_path(@session), notice: "Note removed."
  end

  private

  def set_session
    @session = ObservationSession.find(params[:observation_session_id])
  end

  def note_params
    params.require(:observation_note).permit(:content, :seconds_into_session)
  end
end
