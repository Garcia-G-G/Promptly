require "test_helper"

class Api::V1::PromptVersionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @workspace = workspaces(:demo)
    @project = projects(:playground)
    @prompt = prompts(:doc_summarizer)
    @raw_key = "pk_test_key_for_fixtures_only"
  end

  test "create pushes a new version" do
    assert_difference -> { @prompt.prompt_versions.count } do
      post api_v1_prompt_versions_path(@prompt.slug),
        params: { content: "New prompt body {name}", variables: [ { "name" => "name" } ] }.to_json,
        headers: api_headers(raw_key: @raw_key)
    end

    assert_response :created
    body = JSON.parse(response.body)
    assert body["version_number"] > 0
    assert_equal "dev", body["environment"]
  end

  test "create requires content" do
    post api_v1_prompt_versions_path(@prompt.slug),
      params: {}.to_json,
      headers: api_headers(raw_key: @raw_key)

    assert_response :bad_request
  end

  test "create rejects invalid API key" do
    post api_v1_prompt_versions_path(@prompt.slug),
      params: { content: "hi" }.to_json,
      headers: api_headers(raw_key: "pk_totally_wrong_key")

    assert_response :unauthorized
  end
end
