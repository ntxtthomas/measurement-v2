class ObservationDimension < ApplicationRecord
  has_many :observation_scores, dependent: :destroy

  validates :name,     presence: true
  validates :code,     presence: true, uniqueness: true
  validates :category, presence: true
  validates :min_score, :max_score, presence: true, numericality: { only_integer: true }

  scope :active,   -> { where(active: true) }
  scope :ordered,  -> { order(:position) }
  scope :by_category, ->(cat) { where(category: cat) }

  CATEGORIES = [
    "Emotional Support",
    "Classroom Organization",
    "Instructional Support"
  ].freeze

  def score_range
    min_score..max_score
  end
end
