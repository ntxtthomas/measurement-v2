class StudentsController < ApplicationController
  def show
    @student = Student.find(params[:id])
    # SMELL: notes loaded without preloading observation_session → classroom → teacher chain
    @notes = @student.observation_notes.order(created_at: :desc)
  end
end
