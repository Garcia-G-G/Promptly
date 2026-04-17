require "test_helper"

class SecurityScanTest < ActiveSupport::TestCase
  test "status enum" do
    scan = SecurityScan.new(prompt_version: prompt_versions(:doc_summarizer_production), status: :clean)
    assert scan.clean?
  end

  test "findings default to empty array" do
    scan = SecurityScan.create!(prompt_version: prompt_versions(:doc_summarizer_production), status: :clean)
    assert_equal [], scan.findings
  end

  test "has injection patterns defined" do
    assert SecurityScan::INJECTION_PATTERNS.any?
    assert SecurityScan::PII_PATTERNS.any?
    assert SecurityScan::ALL_PATTERNS.any?
  end
end
