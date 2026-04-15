require "test_helper"

class Api::V1::PromptsControllerTest < ActionDispatch::IntegrationTest
  # --- Auth tests ---

  test "missing auth header returns 401" do
    get api_v1_prompts_path, headers: { "X-Promptly-Project" => "playground" }
    assert_response :unauthorized
    assert_equal "invalid_api_key", response.parsed_body["error"]
  end

  test "wrong key returns 401" do
    get api_v1_prompts_path, headers: api_headers(raw_key: "pk_wrong_key")
    assert_response :unauthorized
  end

  test "revoked key returns 401" do
    get api_v1_prompts_path, headers: api_headers(raw_key: "pk_revoked_key_for_fixtures_only")
    assert_response :unauthorized
  end

  test "valid key updates last_used_at" do
    key = api_keys(:demo_key)
    assert_nil key.last_used_at

    get api_v1_prompts_path, headers: api_headers
    assert_response :success

    key.reload
    assert_not_nil key.last_used_at
  end

  test "missing project header returns 400" do
    get api_v1_prompts_path, headers: api_headers(project_slug: nil)
    assert_response :bad_request
    assert_equal "missing_project", response.parsed_body["error"]
  end

  # --- List prompts ---

  test "GET /prompts returns project-scoped list" do
    get api_v1_prompts_path, headers: api_headers
    assert_response :success
    body = response.parsed_body
    assert_kind_of Array, body
    slugs = body.map { |p| p["slug"] }
    assert_includes slugs, "doc-summarizer"
  end

  # --- Create prompt ---

  test "POST /prompts creates a prompt" do
    post api_v1_prompts_path,
      params: { slug: "new-prompt", description: "A new one" }.to_json,
      headers: api_headers
    assert_response :created
    assert_equal "new-prompt", response.parsed_body["slug"]
  end

  test "POST /prompts with duplicate slug returns 422" do
    post api_v1_prompts_path,
      params: { slug: "doc-summarizer" }.to_json,
      headers: api_headers
    assert_response :unprocessable_entity
    assert_equal "validation_failed", response.parsed_body["error"]
  end

  # --- Show prompt ---

  test "GET /prompts/:slug returns prompt with active versions" do
    get api_v1_prompt_path(slug: "doc-summarizer"), headers: api_headers
    assert_response :success
    body = response.parsed_body
    assert_equal "doc-summarizer", body["slug"]
    assert body["active_versions"].is_a?(Array)
  end

  # --- Push version ---

  test "POST /prompts/:slug/versions pushes a new version" do
    # First archive the existing dev version
    prompt_versions(:doc_summarizer_dev).update!(environment: :archived)

    post api_v1_prompt_versions_path(prompt_slug: "doc-summarizer"),
      params: { content: "New prompt content" }.to_json,
      headers: api_headers
    assert_response :created
    body = response.parsed_body
    assert_equal "dev", body["environment"]
    assert body["version_number"] >= 1
  end

  # --- Promote ---

  test "POST /prompts/:slug/promote promotes version" do
    version = prompt_versions(:doc_summarizer_dev)
    post promote_api_v1_prompt_path(slug: "doc-summarizer"),
      params: { version_id: version.id, to_environment: "staging" }.to_json,
      headers: api_headers
    assert_response :created
    assert_equal "staging", response.parsed_body["environment"]
  end

  # --- Resolve ---

  test "POST /prompts/:slug/resolve returns production version by default" do
    post resolve_api_v1_prompt_path(slug: "doc-summarizer"),
      headers: api_headers
    assert_response :success
    body = response.parsed_body
    assert body["content"].present?
    assert body["version_number"].present?
    assert body["content_hash"].present?
    assert body["variables_schema"].is_a?(Array)
    assert_equal response.headers["X-Promptly-Version"], body["version_number"].to_s
    assert_equal response.headers["X-Promptly-Content-Hash"], body["content_hash"]
  end

  test "POST /prompts/:slug/resolve with explicit environment" do
    post resolve_api_v1_prompt_path(slug: "doc-summarizer"),
      params: { environment: "dev" }.to_json,
      headers: api_headers
    assert_response :success
    body = response.parsed_body
    assert_includes body["content"], "{language}"
  end

  test "POST /prompts/:slug/resolve with no active version returns 404" do
    post resolve_api_v1_prompt_path(slug: "empty-prompt"),
      headers: api_headers
    assert_response :not_found
    assert_equal "no_active_version", response.parsed_body["error"]
  end

  test "POST /prompts/:slug/resolve with unknown slug returns 404" do
    post resolve_api_v1_prompt_path(slug: "nonexistent"),
      headers: api_headers
    assert_response :not_found
  end

  # --- Log stub ---

  test "POST /prompts/:slug/log returns 202 accepted" do
    post log_api_v1_prompt_path(slug: "doc-summarizer"),
      params: { output: "This is the model output." }.to_json,
      headers: api_headers
    assert_response :accepted
    body = response.parsed_body
    assert body["accepted"]
    assert_not_nil body["log_id"]
  end

  # --- X-Promptly-Key alternative auth ---

  test "X-Promptly-Key header works for auth" do
    get api_v1_prompts_path,
      headers: { "X-Promptly-Key" => "pk_test_key_for_fixtures_only", "X-Promptly-Project" => "playground" }
    assert_response :success
  end

  # --- Cross-workspace security ---

  test "API key cannot access project from different workspace" do
    other_workspace = Workspace.create!(name: "Other", slug: "other-ws", owner: users(:owner))
    Project.create!(workspace: other_workspace, name: "Secret", slug: "secret-project")

    get api_v1_prompts_path, headers: api_headers(project_slug: "secret-project")
    assert_response :not_found
  end

  test "nonexistent project returns 404" do
    get api_v1_prompts_path, headers: api_headers(project_slug: "does-not-exist")
    assert_response :not_found
  end

  # --- Error response consistency ---

  test "all error responses include message field" do
    get api_v1_prompts_path, headers: api_headers(project_slug: nil)
    body = response.parsed_body
    assert body.key?("error")
    assert body.key?("message")
  end

  test "401 error includes message" do
    get api_v1_prompts_path, headers: { "X-Promptly-Project" => "playground" }
    body = response.parsed_body
    assert_equal "invalid_api_key", body["error"]
    assert body["message"].present?
  end

  # --- Promote edge cases ---

  test "promote to invalid environment returns 422" do
    version = prompt_versions(:doc_summarizer_dev)
    post promote_api_v1_prompt_path(slug: "doc-summarizer"),
      params: { version_id: version.id, to_environment: "dev" }.to_json,
      headers: api_headers
    assert_response :unprocessable_entity
  end
end
