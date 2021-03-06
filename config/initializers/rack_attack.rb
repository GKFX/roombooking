# frozen_string_literal: true

Rails.application.config.middleware.use Roombooking::Middleware::RateLimiter
Rails.application.config.middleware.use Rack::Attack

# Blacklist IPs using the cache
# To add an IP: Rails.cache.write("blocklist 1.2.3.4", true, expires_in: 2.days)
# To remove an IP: Rails.cache.delete("blocklist 1.2.3.4")
Rack::Attack.blocklist('block IP') do |request|
  Rails.cache.read("blocklist #{request.ip}")
end

# Limit all IP addresses to 60rpm.
Rack::Attack.throttle('requests by ip', limit: 300, period: 5.minutes) do |request|
  request.ip
end

# Prevent brute-force login or 2FA attempts.
Rack::Attack.throttle('logins by ip', limit: 5, period: 20.seconds) do |request|
  if request.path == '/login' || request.path == '/auth/2fa'
    request.ip
  end
end
