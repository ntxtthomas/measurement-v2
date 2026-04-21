class ApplicationJob < ActiveJob::Base
  # Retry up to 3 times with exponential backoff.
  # NOTE: See GenerateReportJob — retries there cause duplicate Report rows
  # because the job is not idempotent. This is an intentional hotspot.
  retry_on StandardError, wait: :polynomially_longer, attempts: 3
end
