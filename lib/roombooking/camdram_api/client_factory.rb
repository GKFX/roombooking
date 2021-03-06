# frozen_string_literal: true

module Roombooking
  module CamdramAPI
    module ClientFactory
      class << self
        def new(token_hash = nil)
          Camdram::Client.new do |config|
            app_id     = ENV['CAMDRAM_APP_ID']
            app_secret = ENV['CAMDRAM_APP_SECRET']
            if token_hash
              config.auth_code(token_hash, app_id, app_secret) do |faraday|
                faraday_connection_builder.call(faraday)
              end
            else
              config.client_credentials(app_id, app_secret) do |faraday|
                faraday_connection_builder(true).call(faraday)
              end
            end
            config.user_agent = Roombooking::CamdramAPI.user_agent
            config.base_url = Roombooking::CamdramAPI.base_url
          end
        end

        private

        def faraday_connection_builder(cache_responses = false)
          Proc.new do |faraday|
            faraday.use(:ddtrace) if ENV['ENABLE_DATADOG_APM']
            faraday.request  :url_encoded
            faraday.response :caching do
              Roombooking::CamdramAPI::ResponseCacheStore
            end if cache_responses && Rails.application.config.action_controller.perform_caching
            faraday.response :logger, Yell['camdram'] do |logger|
              logger.filter(/Bearer[^"]*/m, '[FILTERED]')
            end
            faraday.adapter :net_http do |http|
              http.open_timeout = socket_timeout
              http.read_timeout = http_timeout
            end
          end
        end

        private

        def socket_timeout
          if Sidekiq.server?
            5
          else
            1.5
          end
        end

        def http_timeout
          if Sidekiq.server?
            10
          else
            3.5
          end
        end
      end
    end
  end
end
