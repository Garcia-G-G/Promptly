require "test_helper"

class LlmSecurityScanJobTest < ActiveJob::TestCase
  test "skips when API key missing" do
    scan = SecurityScan.create!(
      prompt_version: prompt_versions(:doc_summarizer_production),
      status: :running
    )

    # Should not raise, just log warning
    assert_nothing_raised do
      LlmSecurityScanJob.perform_now(security_scan_id: scan.id)
    end
  end

  test "discards when scan not found" do
    assert_nothing_raised do
      LlmSecurityScanJob.perform_now(security_scan_id: -1)
    end
  end
end
