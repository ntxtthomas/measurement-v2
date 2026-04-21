class Story < ApplicationRecord
  belongs_to :epic
  has_many :tasks, -> { order(:position) }, dependent: :destroy

  validates :name, presence: true

  def completion_percentage
    total = tasks.count
    return 0 if total.zero?

    (tasks.where(status: :done).count.to_f / total * 100).round
  end

  def status_summary
    counts = tasks.group(:status).count
    {
      not_started: counts[0] || 0,
      in_progress: counts[1] || 0,
      blocked:     counts[2] || 0,
      done:        counts[3] || 0
    }
  end
end
