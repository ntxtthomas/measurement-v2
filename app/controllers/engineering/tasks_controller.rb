module Engineering
  class TasksController < ApplicationController
    def update
      @task = Task.find(params[:id])

      if @task.update(task_params)
        # SMELL: Hard-coded redirect back — brittle, depends on referrer header
        redirect_back fallback_location: engineering_root_path, notice: "Task updated."
      else
        redirect_back fallback_location: engineering_root_path, alert: "Could not update task."
      end
    end

    private

    def task_params
      params.require(:task).permit(:status, :notes)
    end
  end
end
