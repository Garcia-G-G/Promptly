# frozen_string_literal: true

module Promptly
  module Instrumentation
    TRACER_NAME = "promptly-ruby"

    class << self
      def wrap(slug, prompt)
        if otel_available? && Promptly.configuration.otel_enabled
          tracer.in_span(
            "promptly.resolve #{slug}",
            attributes: otel_attributes(slug, prompt),
            kind: :client
          ) do |span|
            result = yield prompt
            span.set_attribute("promptly.variant", prompt.variant) if prompt.variant
            result
          end
        else
          yield prompt
        end
      end

      private

      def otel_available?
        return @otel_available if defined?(@otel_available)
        @otel_available = begin
          require "opentelemetry-api"
          true
        rescue LoadError
          false
        end
      end

      def tracer
        OpenTelemetry.tracer_provider.tracer(TRACER_NAME, Promptly::VERSION)
      end

      def otel_attributes(slug, prompt)
        {
          "gen_ai.system" => "promptly",
          "gen_ai.request.model" => prompt.model_hint || "",
          "promptly.prompt.slug" => slug,
          "promptly.prompt.version" => prompt.version.to_s,
          "promptly.prompt.environment" => prompt.environment.to_s,
          "promptly.request_id" => prompt.request_id
        }
      end
    end
  end
end
