class Rack::Attack
  # Global IP-based throttle for API endpoints
  throttle("api/ip", limit: 1000, period: 60) do |req|
    req.ip if req.path.start_with?("/api/")
  end

  # Per-API-key throttle (more granular than IP)
  throttle("api/key", limit: 300, period: 60) do |req|
    if req.path.start_with?("/api/")
      auth = req.env["HTTP_AUTHORIZATION"]
      if auth&.start_with?("Bearer ")
        auth.delete_prefix("Bearer ").strip
      else
        req.env["HTTP_X_PROMPTLY_KEY"]
      end
    end
  end

  # Brute-force login protection
  throttle("login/ip", limit: 20, period: 60) do |req|
    req.ip if req.path == "/users/sign_in" && req.post?
  end

  # Custom JSON response for throttled requests
  self.throttled_responder = lambda do |req|
    match_data = req.env["rack.attack.match_data"]
    retry_after = (match_data || {})[:period]

    headers = {
      "Content-Type" => "application/json",
      "Retry-After" => retry_after.to_s
    }

    body = { error: "rate_limited", message: "Rate limit exceeded. Retry after #{retry_after} seconds." }

    [ 429, headers, [ body.to_json ] ]
  end
end
