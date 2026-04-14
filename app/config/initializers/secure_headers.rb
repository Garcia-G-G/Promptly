SecureHeaders::Configuration.default do |config|
  config.hsts = "max-age=631138519; includeSubDomains"
  config.x_frame_options = "DENY"
  config.x_content_type_options = "nosniff"
  config.x_xss_protection = "0"
  config.x_permitted_cross_domain_policies = "none"
  config.referrer_policy = %w[strict-origin-when-cross-origin]

  config.csp = {
    default_src: %w['self'],
    script_src: %w['self' 'unsafe-inline'],
    style_src: %w['self' 'unsafe-inline'],
    connect_src: %w['self' ws://localhost:* wss://localhost:*],
    img_src: %w['self' data:],
    font_src: %w['self'],
    frame_ancestors: %w['none'],
    form_action: %w['self'],
    base_uri: %w['self']
  }
end
