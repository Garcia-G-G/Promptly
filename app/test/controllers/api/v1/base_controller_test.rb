require "test_helper"

class Api::V1::PromptsControllerTest < ActionDispatch::IntegrationTest
  test "resolve returns 401 without authentication" do
    post resolve_api_v1_prompt_path(slug: "test-prompt")
    assert_response :unauthorized
    assert_equal "application/json", response.media_type

    body = JSON.parse(response.body)
    assert_equal "invalid_api_key", body["error"]
  end

  test "log returns 401 without authentication" do
    post log_api_v1_prompt_path(slug: "test-prompt")
    assert_response :unauthorized
    assert_equal "application/json", response.media_type

    body = JSON.parse(response.body)
    assert_equal "invalid_api_key", body["error"]
  end
end
