class Rack::Attack
  throttle("api/ip", limit: 1000, period: 60) do |req|
    req.ip if req.path.start_with?("/api/")
  end

  throttle("login/ip", limit: 20, period: 60) do |req|
    req.ip if req.path == "/users/sign_in" && req.post?
  end
end
