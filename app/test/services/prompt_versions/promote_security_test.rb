require "test_helper"

class PromptVersions::PromoteSecurityTest < ActiveSupport::TestCase
  test "blocked by flagged scan when promoting to production" do
    version = prompt_versions(:doc_summarizer_dev)
    SecurityScan.create!(prompt_version: version, status: :flagged, findings: [ { "type" => "injection" } ])

    assert_raises PromptVersions::SecurityBlocked do
      PromptVersions::Promote.call(prompt_version: version, to_environment: :production)
    end
  end

  test "allowed with force: true despite flagged scan" do
    version = prompt_versions(:doc_summarizer_dev)
    SecurityScan.create!(prompt_version: version, status: :flagged, findings: [ { "type" => "injection" } ])

    result = PromptVersions::Promote.call(prompt_version: version, to_environment: :production, force: true)
    assert result.persisted?
    assert_equal "production", result.environment
  end

  test "staging promotion is not gated by security scan" do
    version = prompt_versions(:doc_summarizer_dev)
    SecurityScan.create!(prompt_version: version, status: :flagged, findings: [ { "type" => "injection" } ])

    result = PromptVersions::Promote.call(prompt_version: version, to_environment: :staging)
    assert result.persisted?
  end
end
