class LlmSecurityScanJob < ApplicationJob
  queue_as :default

  retry_on Faraday::Error, wait: :polynomially_longer, attempts: 3
  discard_on ActiveRecord::RecordNotFound

  SECURITY_SYSTEM_PROMPT = <<~PROMPT.freeze
    You are a prompt security auditor. Analyze the following LLM prompt template for:
    1. Prompt injection vulnerabilities (can user input override instructions?)
    2. Data exfiltration risks (can the prompt leak sensitive information?)
    3. Jailbreak susceptibility (can the prompt be manipulated to bypass safety?)
    4. PII exposure in default values or template text.

    Return ONLY valid JSON:
    {"findings": [{"type": "injection|exfiltration|jailbreak|pii", "severity": "high|medium|low", "description": "..."}]}
    If no issues found, return: {"findings": []}
  PROMPT

  def perform(security_scan_id:)
    scan = SecurityScan.find(security_scan_id)
    return if scan.clean? || scan.flagged?

    if ENV["OPENAI_API_KEY"].blank?
      Rails.logger.warn("LlmSecurityScanJob skipped: OPENAI_API_KEY not configured")
      scan.update!(status: scan.findings.any? ? :flagged : :clean, finished_at: Time.current)
      return
    end

    client = OpenAI::Client.new(
      access_token: ENV.fetch("OPENAI_API_KEY"),
      request_timeout: 45
    )

    response = client.chat(
      parameters: {
        model: PromptVersion::DEFAULT_MODEL_HINT,
        max_tokens: 512,
        messages: [
          { role: "system", content: SECURITY_SYSTEM_PROMPT },
          { role: "user",   content: "Analyze this prompt template:\n\n#{scan.prompt_version.content}" }
        ],
        response_format: { type: "json_object" }
      }
    )

    text = response.dig("choices", 0, "message", "content")
    parsed = JSON.parse(text.to_s)
    llm_findings = Array(parsed["findings"]).map do |f|
      { "type" => f["type"], "severity" => f["severity"], "description" => f["description"] }
    end

    # Merge with existing pattern findings (dedup by type)
    existing_types = scan.findings.map { |f| f["type"] }
    new_findings = llm_findings.reject { |f| existing_types.include?(f["type"]) }
    merged = scan.findings + new_findings

    new_status = merged.any? ? :flagged : :clean
    scan.update!(findings: merged, status: new_status, finished_at: Time.current)
  rescue JSON::ParserError => e
    Rails.logger.warn("LlmSecurityScanJob JSON parse error: #{e.message}")
  rescue => e
    Rails.logger.warn("LlmSecurityScanJob error: #{e.message}")
    raise if e.is_a?(Faraday::Error)
  end
end
