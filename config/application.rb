# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Roombooking
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Use Redis for caching and report exceptions to Sentry as warnings.
    config.cache_store = :redis_cache_store, {
      url: ENV['REDIS_CACHE'], error_handler: lambda do |params|
        exception = params[:exception]
        method = params[:method]
        returning = params[:returning]
        Raven.capture_exception exception, level: 'warning',
          tags: { method: method, returning: returning }
      end
    }

    config.time_zone = 'London'
    config.beginning_of_week = :sunday
    config.eager_load_paths << Rails.root.join('lib')
    config.action_mailer.default_url_options = { host: 'roombooking-dev.adctheatre.com' }

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
  end
end
