module Serializers
  class SecurityScanSerializer
    def self.call(scan)
      {
        id: scan.id,
        prompt_version_id: scan.prompt_version_id,
        status: scan.status,
        findings: scan.findings,
        started_at: scan.started_at&.iso8601,
        finished_at: scan.finished_at&.iso8601,
        created_at: scan.created_at.iso8601
      }
    end
  end
end
