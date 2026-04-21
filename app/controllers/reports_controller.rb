class ReportsController < ApplicationController
  def index
    # SMELL: No pagination, no scoping to current observer's org
    @reports = Report.completed.recent.limit(50)
  end

  def show
    @report  = Report.find(params[:id])
    @session = @report.observation_session
    @parsed  = @report.parsed_content
  end

  # SMELL: Regeneration is synchronous, produces a duplicate Report row,
  # and does not guard against concurrent requests — classic non-idempotency.
  def regenerate
    @report = Report.find(params[:id])
    @session = @report.observation_session

    unless @session.finalized?
      return redirect_to report_path(@report), alert: "Session is not finalized."
    end

    # SMELL: Directly enqueues the non-idempotent job — will create another Report row
    GenerateReportJob.perform_later(@session.id)
    redirect_to report_path(@report), notice: "Report regeneration queued."
  end
end
