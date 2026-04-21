class Report < ApplicationRecord
  belongs_to :observation_session

  enum status: { pending: 0, generating: 1, complete: 2, failed: 3 }

  validates :generated_by, presence: true

  scope :recent,    -> { order(created_at: :desc) }
  scope :completed, -> { where(status: :complete) }

  def parsed_content
    return nil unless content.present?

    JSON.parse(content)
  rescue JSON::ParserError => e
    Rails.logger.error "Report#parsed_content failed: #{e.message}"
    nil
  end
end
