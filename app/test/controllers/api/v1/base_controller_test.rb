require "test_helper"

class Api::V1::PromptsControllerTest < ActionDispatch::IntegrationTest
  test "resolve returns 501 without authentication" do
    post api_v1_prompt_resolve_path(slug: "test-prompt")
    assert_response :not_implemented
    assert_equal "application/json", response.media_type

    body = JSON.parse(response.body)
    assert_equal "not_implemented", body["status"]
  end

  test "log returns 501 without authentication" do
    post api_v1_prompt_log_path(slug: "test-prompt")
    assert_response :not_implemented
    assert_equal "application/json", response.media_type

    body = JSON.parse(response.body)
    assert_equal "not_implemented", body["status"]
  end
end
