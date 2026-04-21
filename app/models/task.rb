class Task < ApplicationRecord
  belongs_to :story

  enum status: { not_started: 0, in_progress: 1, blocked: 2, done: 3 }

  validates :name, presence: true

  scope :incomplete, -> { where.not(status: :done) }
  scope :ordered,    -> { order(:position) }
end
