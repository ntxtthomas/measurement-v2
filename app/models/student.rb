class Student < ApplicationRecord
  belongs_to :classroom

  has_many :observation_note_students, dependent: :destroy
  has_many :observation_notes, through: :observation_note_students

  validates :first_name, presence: true
  validates :last_name,  presence: true

  def full_name
    "#{first_name} #{last_name}"
  end
end
