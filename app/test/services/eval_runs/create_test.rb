require "test_helper"

class EvalRuns::CreateTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "creates eval run and enqueues job" do
    assert_enqueued_with(job: RunEvalJob) do
      run = EvalRuns::Create.call(
        prompt_version: prompt_versions(:doc_summarizer_production),
        dataset: datasets(:summarizer_cases),
        scorer: scorers(:exact_match_scorer)
      )
      assert run.queued?
      assert_equal 2, run.total_rows
    end
  end
end
