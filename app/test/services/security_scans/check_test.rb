require "test_helper"

class SecurityScans::CheckTest < ActiveSupport::TestCase
  test "allowed when no scan exists" do
    result = SecurityScans::Check.call(prompt_version: prompt_versions(:doc_summarizer_production))
    assert result[:allowed]
  end

  test "allowed when clean" do
    SecurityScan.create!(prompt_version: prompt_versions(:doc_summarizer_production), status: :clean)
    result = SecurityScans::Check.call(prompt_version: prompt_versions(:doc_summarizer_production))
    assert result[:allowed]
  end

  test "blocked when flagged" do
    SecurityScan.create!(prompt_version: prompt_versions(:doc_summarizer_production), status: :flagged, findings: [ { "type" => "injection" } ])
    result = SecurityScans::Check.call(prompt_version: prompt_versions(:doc_summarizer_production))
    assert_not result[:allowed]
  end
end
