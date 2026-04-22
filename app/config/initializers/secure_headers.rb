SecureHeaders::Configuration.default do |config|
  config.hsts = "max-age=31536000; includeSubDomains"
  config.x_frame_options = "DENY"
  config.x_content_type_options = "nosniff"
  config.x_xss_protection = "0"
  config.x_permitted_cross_domain_policies = "none"
  config.referrer_policy = %w[strict-origin-when-cross-origin]

  connect_sources = %w['self']
  connect_sources += %w[ws://localhost:* wss://localhost:*] if Rails.env.local?

  # NOTE: inline styles are kept ('unsafe-inline' for style_src) because
  # the dashboard composes layout via inline style="" attributes.
  # Moving to nonces would require rewriting every view.
  # Inline scripts are similarly retained for the handful of onclick
  # attributes (Turbo.visit, class toggles). Tighten these when those
  # handlers are migrated to Stimulus.
  config.csp = {
    default_src:     %w['self'],
    script_src:      %w['self' 'unsafe-inline'],
    style_src:       %w['self' 'unsafe-inline' https://fonts.googleapis.com],
    font_src:        %w['self' https://fonts.gstatic.com data:],
    img_src:         %w['self' data: https:],
    connect_src:     connect_sources,
    frame_ancestors: %w['none'],
    form_action:     %w['self'],
    base_uri:        %w['self'],
    object_src:      %w['none'],
    manifest_src:    %w['self']
  }
end
