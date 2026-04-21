source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.4.7"

gem "rails", "~> 7.1.0"
gem "pg", "~> 1.1"
gem "puma", "~> 6.0"
gem "redis", "~> 5.0"
gem "sidekiq", "~> 7.2"

# Frontend
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "sprockets-rails"

# Auth
gem "bcrypt", "~> 3.1.7"

# Pagination — intentionally not applied everywhere (see hotspots)
gem "kaminari", "~> 1.2"

# Utilities
gem "bootsnap", require: false
gem "tzinfo-data", platforms: %i[windows jruby]

group :development, :test do
  gem "debug", platforms: %i[mri windows]
  gem "rspec-rails", "~> 6.1"
  gem "factory_bot_rails"
  gem "faker"
  gem "pry-rails"
end

group :development do
  gem "web-console"
  gem "rack-mini-profiler"   # Helpful for spotting slow queries locally
  gem "bullet"               # N+1 detection — see config/environments/development.rb
  gem "annotate"             # Schema annotations on models
end

group :test do
  gem "shoulda-matchers", "~> 5.0"
  gem "database_cleaner-active_record"
end
