class SchoolsController < ApplicationController
  def show
    @school = School.find(params[:id])
    # SMELL: Teachers and classrooms rendered in view without eager loading
    @classrooms = @school.classrooms.order(:name)
    @teachers   = @school.teachers.order(:last_name, :first_name)
  end
end
