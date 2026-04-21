class ObservationScoresController < ApplicationController
  before_action :set_session

  def create
    @score = ObservationScore.new(score_params.merge(observation_session: @session))

    if @score.save
      render json: { status: "ok", score_id: @score.id }
    else
      render json: { errors: @score.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    @score = ObservationScore.find(params[:id])

    if @score.update(score_params)
      render json: { status: "ok" }
    else
      render json: { errors: @score.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_session
    @session = ObservationSession.find(params[:observation_session_id])
  end

  def score_params
    params.require(:observation_score).permit(:observation_dimension_id, :score)
  end
end
