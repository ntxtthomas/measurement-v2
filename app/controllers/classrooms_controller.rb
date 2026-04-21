class ClassroomsController < ApplicationController
  def show
    @classroom = Classroom.find(params[:id])
    @students  = @classroom.students.order(:last_name, :first_name)
    # SMITH: No pagination — returns all sessions regardless of count
    @sessions  = @classroom.observation_sessions.order(observed_on: :desc)
  end
end
