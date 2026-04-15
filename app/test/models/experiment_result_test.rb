require "test_helper"

class ExperimentResultTest < ActiveSupport::TestCase
  test "valid experiment result" do
    log = Log.create!(
      prompt: prompts(:doc_summarizer),
      prompt_version: prompt_versions(:doc_summarizer_production),
      project: projects(:playground),
      output: "test output"
    )
    exp = Experiment.create!(
      prompt: prompts(:doc_summarizer), name: "er-test",
      variant_a_version: prompt_versions(:doc_summarizer_production),
      variant_b_version: prompt_versions(:doc_summarizer_dev),
      status: :running, started_at: Time.current
    )
    er = ExperimentResult.new(experiment: exp, log: log, variant: "a")
    assert er.valid?
  end

  test "variant must be a or b" do
    log = Log.create!(
      prompt: prompts(:doc_summarizer),
      prompt_version: prompt_versions(:doc_summarizer_production),
      project: projects(:playground),
      output: "test"
    )
    exp = Experiment.create!(
      prompt: prompts(:doc_summarizer), name: "er-invalid",
      variant_a_version: prompt_versions(:doc_summarizer_production),
      variant_b_version: prompt_versions(:doc_summarizer_dev),
      status: :draft
    )
    er = ExperimentResult.new(experiment: exp, log: log, variant: "c")
    assert_not er.valid?
  end
end
