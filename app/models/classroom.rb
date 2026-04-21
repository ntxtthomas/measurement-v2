class Classroom < ApplicationRecord
  belongs_to :school
  belongs_to :teacher, optional: true

  has_many :students,             dependent: :destroy
  has_many :observation_sessions, dependent: :destroy

  validates :name, presence: true

  # INTENTIONAL: last_observed_at is updated via a callback on ObservationSession
  # finalization. It can fall out of sync if sessions are destroyed manually.
end
