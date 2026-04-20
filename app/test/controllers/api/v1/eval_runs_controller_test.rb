require "test_helper"

class Api::V1::EvalRunsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  test "POST /eval_runs creates and enqueues" do
    assert_enqueued_with(job: RunEvalJob) do
      post api_v1_eval_runs_path,
        params: {
          prompt_version_id: prompt_versions(:doc_summarizer_production).id,
          dataset_id: datasets(:summarizer_cases).id,
          scorer_id: scorers(:exact_match_scorer).id
        }.to_json,
        headers: api_headers
    end
    assert_response :created
    assert_equal "queued", response.parsed_body["status"]
  end

  test "GET /eval_runs lists runs" do
    EvalRun.create!(
      prompt_version: prompt_versions(:doc_summarizer_production),
      dataset: datasets(:summarizer_cases),
      scorer: scorers(:exact_match_scorer)
    )
    get api_v1_eval_runs_path, headers: api_headers
    assert_response :success
    assert_kind_of Array, response.parsed_body
  end

  test "GET /eval_runs/:id shows run with results" do
    run = EvalRun.create!(
      prompt_version: prompt_versions(:doc_summarizer_production),
      dataset: datasets(:summarizer_cases),
      scorer: scorers(:exact_match_scorer)
    )
    get api_v1_eval_run_path(id: run.id), headers: api_headers
    assert_response :success
    assert response.parsed_body.key?("results")
  end
end
