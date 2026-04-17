require "test_helper"

class EvalRuns::CompleteTest < ActiveSupport::TestCase
  test "computes aggregate score and pass rate" do
    run = EvalRun.create!(
      prompt_version: prompt_versions(:doc_summarizer_production),
      dataset: datasets(:summarizer_cases),
      scorer: scorers(:exact_match_scorer),
      status: :running,
      total_rows: 3,
      pass_threshold: 0.5
    )

    # Create results: 2 pass, 1 fail
    EvalRunResult.create!(eval_run: run, dataset_row: dataset_rows(:spanish_bullets), score: 0.8, output: "good")
    EvalRunResult.create!(eval_run: run, dataset_row: dataset_rows(:english_paragraph), score: 0.3, output: "bad")

    EvalRuns::Complete.call(eval_run: run)
    run.reload

    assert run.done?
    assert_in_delta 0.55, run.aggregate_score, 0.01
    assert_in_delta 0.5, run.pass_rate, 0.01  # 1 out of 2 passes threshold 0.5
    assert_equal 2, run.scored_rows
  end
end
