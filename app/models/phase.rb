class Phase < ApplicationRecord
  has_many :epics, -> { order(:position) }, dependent: :destroy
  has_many :stories, through: :epics
  has_many :tasks,   through: :stories

  validates :name, presence: true

  default_scope { order(:position) }

  # INTENTIONAL: These methods load all tasks — no caching, no counter_cache.
  # The engineering dashboard makes 7+ queries here for all phases.
  def total_task_count
    tasks.count
  end

  def done_task_count
    tasks.where(status: :done).count
  end

  def completion_percentage
    total = total_task_count
    return 0 if total.zero?

    (done_task_count.to_f / total * 100).round
  end

  def status_label
    pct = completion_percentage
    if pct == 100
      "Complete"
    elsif pct > 0
      "In Progress"
    else
      "Not Started"
    end
  end
end
