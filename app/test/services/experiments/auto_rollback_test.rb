require "test_helper"

class Experiments::AutoRollbackTest < ActiveSupport::TestCase
  test "pauses experiment when scores below threshold" do
    prompt = prompts(:doc_summarizer)
    experiment = Experiment.create!(
      prompt: prompt, name: "rollback-test",
      variant_a_version: prompt_versions(:doc_summarizer_production),
      variant_b_version: prompt_versions(:doc_summarizer_dev),
      status: :running, started_at: Time.current,
      canary_stage: 10, auto_rollback_threshold: 0.5
    )

    log = Log.create!(prompt: prompt, prompt_version: prompt_versions(:doc_summarizer_production), project: projects(:playground), output: "test")

    50.times { ExperimentResult.create!(experiment: experiment, log: log, variant: "b", score: 0.2) }

    Experiments::AutoRollback.call(experiment: experiment)
    experiment.reload
    assert_equal "paused", experiment.status
  end

  test "does not rollback when scores above threshold" do
    prompt = prompts(:doc_summarizer)
    experiment = Experiment.create!(
      prompt: prompt, name: "no-rollback",
      variant_a_version: prompt_versions(:doc_summarizer_production),
      variant_b_version: prompt_versions(:doc_summarizer_dev),
      status: :running, started_at: Time.current,
      canary_stage: 10, auto_rollback_threshold: 0.5
    )

    log = Log.create!(prompt: prompt, prompt_version: prompt_versions(:doc_summarizer_production), project: projects(:playground), output: "test")

    50.times { ExperimentResult.create!(experiment: experiment, log: log, variant: "b", score: 0.8) }

    Experiments::AutoRollback.call(experiment: experiment)
    experiment.reload
    assert_equal "running", experiment.status
  end
end
