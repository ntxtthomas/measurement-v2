class ObservationScore < ApplicationRecord
  belongs_to :observation_session
  belongs_to :observation_dimension

  validates :score, presence: true, numericality: { only_integer: true }
  validate  :score_within_dimension_range

  private

  def score_within_dimension_range
    return unless score && observation_dimension

    unless score.between?(observation_dimension.min_score, observation_dimension.max_score)
      errors.add(:score, "must be between #{observation_dimension.min_score} and #{observation_dimension.max_score}")
    end
  end
end
