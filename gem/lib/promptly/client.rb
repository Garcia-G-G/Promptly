# frozen_string_literal: true

module Promptly
  class Client
    MAX_RETRIES = 2
    RETRY_DELAY = 0.5

    def initialize(config)
      @config = config
      @base_uri = URI.parse(config.base_url)
    end

    def post(path, payload)
      body = JSON.generate(payload)
      attempt = 0

      begin
        attempt += 1
        uri = URI.join(@base_uri.to_s.chomp("/") + "/", path.sub(%r{^/}, ""))
        http = build_http(uri)
        request = build_request(uri, body)

        response = http.request(request)
        handle_response(response)
      rescue Net::OpenTimeout, Net::ReadTimeout => e
        raise Promptly::TimeoutError, "Request timed out after #{@config.timeout}s: #{e.message}"
      rescue Errno::ECONNREFUSED, Errno::ECONNRESET, SocketError => e
        if attempt <= MAX_RETRIES
          sleep(RETRY_DELAY * attempt)
          retry
        end
        raise Promptly::ConnectionError, "Failed to connect to #{@config.base_url}: #{e.message}"
      end
    end

    private

    def build_http(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      http.open_timeout = @config.timeout
      http.read_timeout = @config.timeout
      http
    end

    def build_request(uri, body)
      req = Net::HTTP::Post.new(uri.request_uri)
      req["Content-Type"] = "application/json"
      req["Accept"] = "application/json"
      req["Authorization"] = "Bearer #{@config.api_key}"
      req["X-Promptly-Project"] = @config.project
      req["User-Agent"] = "promptly-ruby/#{Promptly::VERSION}"
      req.body = body
      req
    end

    def handle_response(response)
      case response.code.to_i
      when 200..299
        JSON.parse(response.body)
      when 401
        raise Promptly::AuthenticationError, "Invalid API key"
      when 403
        raise Promptly::ForbiddenError, "Access denied: #{response.body}"
      when 404
        raise Promptly::NotFoundError, "Resource not found: #{response.body}"
      when 422
        raise Promptly::ValidationError, "Validation failed: #{response.body}"
      when 429
        raise Promptly::RateLimitError, "Rate limit exceeded. Retry after #{response['Retry-After']}s"
      when 500..599
        raise Promptly::ServerError, "Server error (#{response.code}): #{response.body}"
      else
        raise Promptly::ApiError, "Unexpected response (#{response.code}): #{response.body}"
      end
    end
  end
end
