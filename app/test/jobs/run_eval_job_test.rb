require "test_helper"

class RunEvalJobTest < ActiveJob::TestCase
  test "processes rows and completes eval run" do
    run = EvalRun.create!(
      prompt_version: prompt_versions(:doc_summarizer_production),
      dataset: datasets(:summarizer_cases),
      scorer: scorers(:exact_match_scorer),
      status: :queued,
      total_rows: 2
    )

    RunEvalJob.perform_now(eval_run_id: run.id)
    run.reload

    assert run.done?
    assert_equal 2, run.eval_run_results.count
    assert run.aggregate_score.present? || run.scored_rows == 0
  end
end
