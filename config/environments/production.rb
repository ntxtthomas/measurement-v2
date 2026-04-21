require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true
  config.force_ssl = true

  config.log_level    = :info
  config.log_tags     = [:request_id]

  config.action_mailer.perform_caching = false
  config.active_support.report_deprecations = false
  config.active_record.dump_schema_after_migration = false

  # TODO: Add Skylight/Honeybadger/NewRelic here when monitoring is needed.
  # See README observability section for guidance.
end
