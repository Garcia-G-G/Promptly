# Sentry is initialised only when SENTRY_DSN is set, so the gem is
# a no-op in development, CI, and self-hosted installs that don't use
# a hosted error tracker.
return unless defined?(Sentry)
return if ENV["SENTRY_DSN"].blank?

Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN"]
  config.environment = Rails.env
  config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]
  config.traces_sample_rate   = ENV.fetch("SENTRY_TRACES_RATE", "0.1").to_f
  config.profiles_sample_rate = ENV.fetch("SENTRY_PROFILES_RATE", "0.1").to_f
  config.send_default_pii = false

  # Scrub prompt payloads and authentication material before shipping
  # events — these overlap with filter_parameter_logging but are
  # belt-and-suspenders for exceptions captured outside the request cycle.
  config.before_send = lambda do |event, _hint|
    if event.respond_to?(:request) && event.request
      data = event.request.data
      if data.is_a?(Hash)
        %w[content output input_vars expected_output score_rationale raw_key api_key].each do |k|
          data.delete(k)
          data.delete(k.to_sym)
        end
      end
      headers = event.request.headers
      if headers.is_a?(Hash)
        %w[Authorization X-Promptly-Key].each { |h| headers.delete(h) }
      end
    end
    event
  end
end
