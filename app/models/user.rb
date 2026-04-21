class User < ApplicationRecord
  has_secure_password

  has_one :observer, dependent: :destroy

  ROLES = %w[admin observer].freeze

  validates :email,      presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :first_name, presence: true
  validates :last_name,  presence: true
  validates :role,       inclusion: { in: ROLES }

  before_save { self.email = email.downcase }

  scope :active, -> { where(active: true) }

  def full_name
    "#{first_name} #{last_name}"
  end

  def admin?
    role == "admin"
  end

  def observer?
    role == "observer"
  end
end
