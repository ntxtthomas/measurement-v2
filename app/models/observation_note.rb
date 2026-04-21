class ObservationNote < ApplicationRecord
  belongs_to :observation_session
  belongs_to :observer

  has_many :observation_note_students, dependent: :destroy
  has_many :students, through: :observation_note_students

  validates :content, presence: true

  scope :with_students, -> { joins(:observation_note_students).distinct }
end
