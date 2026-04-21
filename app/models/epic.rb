class Epic < ApplicationRecord
  belongs_to :phase
  has_many :stories, -> { order(:position) }, dependent: :destroy
  has_many :tasks, through: :stories

  validates :name, presence: true

  def completion_percentage
    total = tasks.count
    return 0 if total.zero?

    (tasks.where(status: :done).count.to_f / total * 100).round
  end
end
