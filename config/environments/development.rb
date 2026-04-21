require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.cache_classes = false
  config.eager_load = false
  config.consider_all_requests_local = true
  config.server_timing = true

  config.action_controller.perform_caching = false
  config.cache_store = :null_store

  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.perform_caching = false
  config.action_mailer.default_url_options = { host: "localhost", port: 3000 }

  config.active_support.deprecation = :log
  config.active_record.migration_error = :page_load
  config.active_record.verbose_query_logs = true

  # ── Bullet gem — N+1 detection ─────────────────────────────────────────
  # Run the app in development, look at logs for N+1 warnings.
  # This will fire frequently given the intentional hotspots in this codebase.
  config.after_initialize do
    Bullet.enable        = true
    Bullet.alert         = true
    Bullet.rails_logger  = true
    Bullet.add_footer    = true
  end

  config.assets.debug = true
  config.assets.quiet = true
end
