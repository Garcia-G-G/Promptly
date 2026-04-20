if ENV["OTEL_EXPORTER_OTLP_ENDPOINT"].present?
  require "opentelemetry/sdk"
  require "opentelemetry/exporter/otlp"

  OpenTelemetry::SDK.configure do |c|
    c.service_name = ENV.fetch("OTEL_SERVICE_NAME", "promptly-api")
    c.service_version = "0.1.0"

    c.use "OpenTelemetry::Instrumentation::Rails" if defined?(OpenTelemetry::Instrumentation::Rails)
    c.use "OpenTelemetry::Instrumentation::PG" if defined?(OpenTelemetry::Instrumentation::PG)
    c.use "OpenTelemetry::Instrumentation::Net::HTTP" if defined?(OpenTelemetry::Instrumentation::Net::HTTP)
    c.use "OpenTelemetry::Instrumentation::Redis" if defined?(OpenTelemetry::Instrumentation::Redis)
  end
end
