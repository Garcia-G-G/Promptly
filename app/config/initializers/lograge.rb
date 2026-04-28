Rails.application.configure do
  next unless Rails.env.production?

  config.lograge.enabled   = true
  config.lograge.formatter = Lograge::Formatters::Json.new

  config.lograge.custom_payload do |controller|
    {
      host:         controller.request.host,
      user_id:      controller.try(:current_user)&.id,
      workspace_id: controller.try(:current_workspace)&.id,
      request_id:   controller.request.request_id
    }
  end

  config.lograge.custom_options = lambda do |event|
    {
      params:        event.payload[:params]&.except("controller", "action", "format"),
      duration_db:   event.payload[:db_runtime]&.round(1),
      duration_view: event.payload[:view_runtime]&.round(1)
    }
  end
end
