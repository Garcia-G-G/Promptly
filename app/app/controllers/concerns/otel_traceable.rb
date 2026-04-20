module OtelTraceable
  extend ActiveSupport::Concern

  private

  def trace_resolve(prompt, version, experiment: nil, variant: nil)
    span = OpenTelemetry::Trace.current_span rescue nil
    return unless span&.recording?

    span.set_attribute("gen_ai.system", "promptly")
    span.set_attribute("gen_ai.operation.name", "resolve")
    span.set_attribute("gen_ai.request.model", version.model_hint || "")
    span.set_attribute("promptly.prompt.slug", prompt.slug)
    span.set_attribute("promptly.prompt.version", version.version_number)
    span.set_attribute("promptly.prompt.environment", version.environment)
    span.set_attribute("promptly.request_id", params[:request_id].to_s)

    if experiment
      span.set_attribute("promptly.experiment.name", experiment.name)
      span.set_attribute("promptly.experiment.id", experiment.id)
      span.set_attribute("promptly.variant", variant.to_s)
    end
  end

  def trace_log(prompt, log_entry)
    span = OpenTelemetry::Trace.current_span rescue nil
    return unless span&.recording?

    span.set_attribute("gen_ai.system", "promptly")
    span.set_attribute("gen_ai.operation.name", "log")
    span.set_attribute("promptly.prompt.slug", prompt.slug)
    span.set_attribute("promptly.request_id", log_entry.request_id.to_s)
    span.set_attribute("promptly.log.latency_ms", log_entry.latency_ms || 0)

    if log_entry.tokens.present?
      span.set_attribute("gen_ai.usage.prompt_tokens", log_entry.tokens["prompt"] || 0)
      span.set_attribute("gen_ai.usage.completion_tokens", log_entry.tokens["completion"] || 0)
    end
  end
end
