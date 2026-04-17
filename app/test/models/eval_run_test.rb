require "test_helper"

class EvalRunTest < ActiveSupport::TestCase
  test "status enum" do
    run = EvalRun.new(
      prompt_version: prompt_versions(:doc_summarizer_production),
      dataset: datasets(:summarizer_cases),
      scorer: scorers(:default_quality),
      status: :queued
    )
    assert run.queued?
  end

  test "has many eval_run_results" do
    run = EvalRun.create!(
      prompt_version: prompt_versions(:doc_summarizer_production),
      dataset: datasets(:summarizer_cases),
      scorer: scorers(:default_quality)
    )
    assert_respond_to run, :eval_run_results
  end
end
