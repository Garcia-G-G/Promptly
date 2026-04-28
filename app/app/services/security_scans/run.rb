module SecurityScans
  class Run
    def self.call(prompt_version:)
      scan = prompt_version.security_scans.create!(status: :running, started_at: Time.current)

      findings = pattern_scan(prompt_version.content)

      if findings.any?
        scan.update!(status: :flagged, findings: findings, finished_at: Time.current)
      else
        scan.update!(status: :clean, findings: [], finished_at: Time.current)
      end

      # Enqueue async LLM deep scan if API key available
      LlmSecurityScanJob.perform_later(security_scan_id: scan.id) if ENV["OPENAI_API_KEY"].present?

      scan
    end

    def self.pattern_scan(content)
      findings = []

      SecurityScan::ALL_PATTERNS.each do |p|
        if p[:pattern].match?(content)
          findings << { type: p[:type], severity: p[:severity], description: "Pattern detected: #{p[:type]}" }
        end
      end

      findings
    end

    private_class_method :pattern_scan
  end
end
