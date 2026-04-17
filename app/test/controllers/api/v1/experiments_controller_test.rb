require "test_helper"

class Api::V1::ExperimentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @v_prod = prompt_versions(:doc_summarizer_production)
    @v_dev = prompt_versions(:doc_summarizer_dev)
  end

  # --- Create ---

  test "POST creates experiment" do
    post api_v1_prompt_experiments_path(prompt_slug: "doc-summarizer"),
      params: {
        name: "new-experiment",
        variant_a_version_id: @v_prod.id,
        variant_b_version_id: @v_dev.id,
        traffic_split: 70
      }.to_json,
      headers: api_headers
    assert_response :created
    body = response.parsed_body
    assert_equal "new-experiment", body["name"]
    assert_equal "draft", body["status"]
    assert_equal 70, body["traffic_split"]
  end

  test "POST with duplicate name returns 422" do
    Experiment.create!(prompt: prompts(:doc_summarizer), name: "dup-test",
      variant_a_version: @v_prod, variant_b_version: @v_dev)

    post api_v1_prompt_experiments_path(prompt_slug: "doc-summarizer"),
      params: { name: "dup-test", variant_a_version_id: @v_prod.id, variant_b_version_id: @v_dev.id }.to_json,
      headers: api_headers
    assert_response :unprocessable_entity
  end

  # --- List ---

  test "GET lists experiments for prompt" do
    Experiment.create!(prompt: prompts(:doc_summarizer), name: "list-test",
      variant_a_version: @v_prod, variant_b_version: @v_dev)

    get api_v1_prompt_experiments_path(prompt_slug: "doc-summarizer"), headers: api_headers
    assert_response :success
    body = response.parsed_body
    assert body.any? { |e| e["name"] == "list-test" }
  end

  # --- Update status ---

  test "PATCH transitions to running" do
    exp = Experiment.create!(prompt: prompts(:doc_summarizer), name: "start-test",
      variant_a_version: @v_prod, variant_b_version: @v_dev, status: :draft)

    patch api_v1_experiment_path(id: exp.id),
      params: { status: "running" }.to_json,
      headers: api_headers
    assert_response :success
    assert_equal "running", response.parsed_body["status"]
    assert response.parsed_body["started_at"].present?
  end

  test "PATCH to concluded sets concluded_at" do
    exp = Experiment.create!(prompt: prompts(:doc_summarizer), name: "conclude-test",
      variant_a_version: @v_prod, variant_b_version: @v_dev,
      status: :running, started_at: Time.current)

    patch api_v1_experiment_path(id: exp.id),
      params: { status: "concluded", winner_version_id: @v_prod.id }.to_json,
      headers: api_headers
    assert_response :success
    body = response.parsed_body
    assert_equal "concluded", body["status"]
    assert body["concluded_at"].present?
  end

  # --- Advance canary ---

  test "POST advance_canary advances stage" do
    exp = Experiment.create!(prompt: prompts(:doc_summarizer), name: "canary-advance",
      variant_a_version: @v_prod, variant_b_version: @v_dev,
      status: :running, started_at: Time.current, canary_stage: 1)

    post advance_canary_api_v1_experiment_path(id: exp.id),
      params: { to: 10 }.to_json,
      headers: api_headers
    assert_response :success
    assert_equal 10, response.parsed_body["canary_stage"]
  end

  test "POST advance_canary backwards returns 422" do
    exp = Experiment.create!(prompt: prompts(:doc_summarizer), name: "canary-back",
      variant_a_version: @v_prod, variant_b_version: @v_dev,
      status: :running, started_at: Time.current, canary_stage: 50)

    post advance_canary_api_v1_experiment_path(id: exp.id),
      params: { to: 10 }.to_json,
      headers: api_headers
    assert_response :unprocessable_entity
  end

  # --- Stats ---

  test "GET stats returns counts" do
    exp = Experiment.create!(prompt: prompts(:doc_summarizer), name: "stats-test",
      variant_a_version: @v_prod, variant_b_version: @v_dev,
      status: :running, started_at: Time.current)

    # Simulate some traffic
    AbRouter::Assign.call(experiment: exp, request_id: "s1")
    AbRouter::Assign.call(experiment: exp, request_id: "s2")

    get stats_api_v1_experiment_path(id: exp.id), headers: api_headers
    assert_response :success
    body = response.parsed_body
    total = body["variant_a"]["count"] + body["variant_b"]["count"]
    assert_equal 2, total
  end

  # --- Resolve with experiment ---

  test "resolve with running experiment returns variant headers" do
    Experiment.create!(prompt: prompts(:doc_summarizer), name: "resolve-exp",
      variant_a_version: @v_prod, variant_b_version: @v_dev,
      status: :running, started_at: Time.current)

    post resolve_api_v1_prompt_path(slug: "doc-summarizer"),
      params: { request_id: "resolve-test-1" }.to_json,
      headers: api_headers
    assert_response :success
    assert response.headers["X-Promptly-Experiment-Id"].present?
    assert_includes %w[a b], response.headers["X-Promptly-Variant"]
    assert_includes %w[experiment not_in_canary], response.headers["X-Promptly-Source"]
  end

  # --- Overlapping running experiment ---

  test "creating second running experiment on same prompt+env fails at DB level" do
    Experiment.create!(prompt: prompts(:doc_summarizer), name: "running-1",
      variant_a_version: @v_prod, variant_b_version: @v_dev,
      status: :running, started_at: Time.current)

    post api_v1_prompt_experiments_path(prompt_slug: "doc-summarizer"),
      params: {
        name: "running-2",
        variant_a_version_id: @v_prod.id,
        variant_b_version_id: @v_dev.id
      }.to_json,
      headers: api_headers
    assert_response :created
    body = response.parsed_body
    # It's created as draft, so this should work
    assert_equal "draft", body["status"]

    # But trying to start it should fail
    patch api_v1_experiment_path(id: body["id"]),
      params: { status: "running" }.to_json,
      headers: api_headers
    # The partial unique index should prevent this
    assert_response :unprocessable_entity
  end
end
