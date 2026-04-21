class ObservationNoteStudent < ApplicationRecord
  belongs_to :observation_note
  belongs_to :student

  validates :observation_note_id, uniqueness: { scope: :student_id }
end
