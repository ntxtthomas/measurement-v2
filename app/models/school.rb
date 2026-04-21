class School < ApplicationRecord
  belongs_to :organization
  has_many :classrooms, dependent: :destroy
  has_many :teachers,   dependent: :destroy
  has_many :students,   through: :classrooms
  has_many :observation_sessions, through: :classrooms

  validates :name, presence: true

  scope :active, -> { where(status: "active") }
end
