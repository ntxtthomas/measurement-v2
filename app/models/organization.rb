class Organization < ApplicationRecord
  has_many :schools,   dependent: :destroy
  has_many :observers, dependent: :destroy
  has_many :classrooms, through: :schools
  has_many :teachers,   through: :schools

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9\-]+\z/ }

  before_validation :generate_slug, on: :create

  scope :active, -> { where(status: "active") }

  def to_param
    slug
  end

  private

  def generate_slug
    self.slug ||= name.to_s.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-|-\z/, "")
  end
end
