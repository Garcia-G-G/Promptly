require "devise/failure_app"

# Devise (via Warden) responds to authentication failures with HTTP 401
# and the sign-in view. Turbo Drive silently ignores 401 HTML responses
# — the form submission appears to do "nothing" to the user. Returning
# 422 instead tells Turbo to replace the form body with the rendered
# response, so the flash alert becomes visible.
#
# This only applies to form-submitted HTML and Turbo Stream requests;
# JSON API clients still receive the standard 401.
class TurboFailureApp < Devise::FailureApp
  def respond
    if turbo_request?
      self.status = 422
      self.content_type = "text/html"
      self.response.headers["Turbo-Frame"] = env["HTTP_TURBO_FRAME"] if env["HTTP_TURBO_FRAME"]
      super
    else
      super
    end
  end

  private

  def turbo_request?
    return false unless request.format.html? || request.format.turbo_stream?
    return true if request.headers["Accept"].to_s.include?("turbo-stream")

    env["HTTP_TURBO_FRAME"].present? || request.xhr?
  end
end
