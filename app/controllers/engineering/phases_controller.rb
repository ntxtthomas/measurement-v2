module Engineering
  class PhasesController < ApplicationController
    def show
      @phase = Phase.find(params[:id])
      # SMELL: No eager loading — epics → stories → tasks resolved lazily in view
      @epics = @phase.epics
    end
  end
end
