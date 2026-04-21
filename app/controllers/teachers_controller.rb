class TeachersController < ApplicationController
  def show
    @teacher = Teacher.find(params[:id])
    # SMELL: No pagination — loads all sessions for this teacher
    @sessions = @teacher.observation_sessions.order(observed_on: :desc)
  end
end
