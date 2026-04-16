class SecurityScan < ApplicationRecord
  INJECTION_PATTERNS = [
    { pattern: /ignore\s+(all\s+)?previous\s+instructions/i, type: "injection", severity: "high" },
    { pattern: /ignore\s+(all\s+)?above/i, type: "injection", severity: "high" },
    { pattern: /disregard\s+(all\s+)?prior/i, type: "injection", severity: "high" },
    { pattern: /you\s+are\s+now/i, type: "role_override", severity: "medium" },
    { pattern: /act\s+as\s+(if\s+you\s+are\s+)?a\s+different/i, type: "role_override", severity: "medium" },
    { pattern: /system\s*prompt/i, type: "prompt_leak", severity: "medium" },
    { pattern: /reveal\s+(your|the)\s+(system|original)\s+prompt/i, type: "prompt_leak", severity: "high" },
    { pattern: /\b(BEGIN|END)\s+INSTRUCTIONS\b/, type: "boundary_marker", severity: "low" }
  ].freeze

  PII_PATTERNS = [
    { pattern: /\b\d{3}-\d{2}-\d{4}\b/, type: "pii_ssn", severity: "high" },
    { pattern: /\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/i, type: "pii_email", severity: "medium" },
    { pattern: /\b\d{16}\b/, type: "pii_credit_card", severity: "high" }
  ].freeze

  ALL_PATTERNS = (INJECTION_PATTERNS + PII_PATTERNS).freeze

  belongs_to :prompt_version

  enum :status, { queued: "queued", running: "running", clean: "clean", flagged: "flagged" }
end
