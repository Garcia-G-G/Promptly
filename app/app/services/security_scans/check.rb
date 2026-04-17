module SecurityScans
  class Check
    def self.call(prompt_version:)
      scan = prompt_version.security_scans.order(created_at: :desc).first

      if scan.nil? || scan.clean?
        { allowed: true, scan: scan }
      else
        { allowed: false, scan: scan }
      end
    end
  end
end
