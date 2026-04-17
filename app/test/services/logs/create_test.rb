require "test_helper"

class Logs::CreateTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @prompt = prompts(:doc_summarizer)
    @project = projects(:playground)
  end

  test "creates a log record" do
    log = Logs::Create.call(
      prompt: @prompt,
      project: @project,
      params: { output: "A summary of the document", input_vars: { language: "English" } }
    )
    assert log.persisted?
    assert_equal "A summary of the document", log.output
  end

  test "creates experiment result when experiment is active" do
    exp = Experiment.create!(
      prompt: @prompt, name: "log-exp-test",
      variant_a_version: prompt_versions(:doc_summarizer_production),
      variant_b_version: prompt_versions(:doc_summarizer_dev),
      status: :running, started_at: Time.current
    )

    # Set up a sticky assignment in Redis
    Promptly::Redis.with do |redis|
      key = Promptly::Redis.key("exp", exp.id, "req", "test-req-123")
      redis.set(key, "a")
    end

    log = Logs::Create.call(
      prompt: @prompt,
      project: @project,
      params: { output: "output", request_id: "test-req-123" }
    )

    assert_equal exp.id, log.experiment_id
    assert_equal "a", log.variant
    assert ExperimentResult.exists?(log_id: log.id, variant: "a")
  end

  test "no experiment result when no experiment" do
    log = Logs::Create.call(
      prompt: @prompt,
      project: @project,
      params: { output: "plain output" }
    )
    assert_nil log.experiment_id
    assert_not ExperimentResult.exists?(log_id: log.id)
  end

  test "enqueues ScoreOutputJob when scorer available" do
    Scorer.create!(project: @project, name: "test-scorer", scorer_type: :llm_judge, content: "Score it")

    assert_enqueued_with(job: ScoreOutputJob) do
      Logs::Create.call(
        prompt: @prompt,
        project: @project,
        params: { output: "to be scored" }
      )
    end
  end
end
