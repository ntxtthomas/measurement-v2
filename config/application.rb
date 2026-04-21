require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module Prism
  class Application < Rails::Application
    config.load_defaults 7.1

    config.time_zone = "UTC"
    config.i18n.default_locale = :en

    config.active_job.queue_adapter = :sidekiq

    # Autoload paths
    config.autoload_lib(ignore: %w[assets tasks])
  end
end
