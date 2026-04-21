class Teacher < ApplicationRecord
  belongs_to :school
  has_many :classrooms, dependent: :nullify
  has_many :observation_sessions, dependent: :nullify

  validates :first_name, presence: true
  validates :last_name,  presence: true

  def full_name
    "#{first_name} #{last_name}"
  end

  # INTENTIONAL: grade_levels is a comma-separated string rather than a proper
  # join table or array column. Works fine at small scale; becomes a problem
  # when you need to query "all teachers who teach Kindergarten."
  def grade_level_list
    grade_levels.to_s.split(",").map(&:strip)
  end
end
