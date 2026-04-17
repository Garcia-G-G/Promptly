# frozen_string_literal: true

module Promptly
  class Error < StandardError; end

  class ConfigurationError < Error; end

  class ApiError < Error; end
  class AuthenticationError < ApiError; end
  class ForbiddenError < ApiError; end
  class NotFoundError < ApiError; end
  class ValidationError < ApiError; end
  class RateLimitError < ApiError; end
  class ServerError < ApiError; end
  class TimeoutError < ApiError; end
  class ConnectionError < ApiError; end
end
