require "test_helper"

class Api::V1::SecurityScansControllerTest < ActionDispatch::IntegrationTest
  test "POST /prompt_versions/:id/security_scan triggers scan" do
    version = prompt_versions(:doc_summarizer_production)
    post api_v1_prompt_version_security_scan_path(prompt_version_id: version.id),
      headers: api_headers
    assert_response :created
    assert_includes %w[clean flagged], response.parsed_body["status"]
  end

  test "GET /prompt_versions/:id/security_scan shows latest scan" do
    version = prompt_versions(:doc_summarizer_production)
    SecurityScan.create!(prompt_version: version, status: :clean)

    get api_v1_prompt_version_security_scan_path(prompt_version_id: version.id),
      headers: api_headers
    assert_response :success
    assert_equal "clean", response.parsed_body["status"]
  end

  test "GET /prompt_versions/:id/security_scan returns 404 when no scan" do
    version = prompt_versions(:doc_summarizer_dev)
    get api_v1_prompt_version_security_scan_path(prompt_version_id: version.id),
      headers: api_headers
    assert_response :not_found
  end
end
