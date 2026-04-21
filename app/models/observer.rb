class Observer < ApplicationRecord
  belongs_to :user
  belongs_to :organization

  has_many :observation_sessions, dependent: :nullify
  has_many :observation_notes,    dependent: :nullify

  CERTIFICATION_LEVELS = %w[trainee standard advanced master].freeze

  validates :certification_level, inclusion: { in: CERTIFICATION_LEVELS }

  scope :active, -> { where(active: true) }

  delegate :full_name, :email, :admin?, to: :user

  def display_name
    "#{user.full_name} (#{certification_level})"
  end
end
