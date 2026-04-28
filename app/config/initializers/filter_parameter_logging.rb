# Be sure to restart your server when you modify this file.
#
# Filter parameters from request logs. Also applies to exception payloads
# forwarded to error trackers (see config/initializers/sentry.rb).
Rails.application.config.filter_parameters += [
  :passw, :email, :secret, :token, :_key, :crypt, :salt,
  :certificate, :otp, :ssn, :cvv, :cvc,

  # Prompt payloads are customer data — never log.
  :content, :output, :input_vars, :expected_output, :score_rationale,

  # External service credentials exchanged via params.
  :access_token, :refresh_token, :api_key, :raw_key,

  # Headers occasionally surface in payloads from middleware.
  /authorization/i, /x.promptly/i
]
