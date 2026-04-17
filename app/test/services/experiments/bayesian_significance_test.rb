require "test_helper"

class Experiments::BayesianSignificanceTest < ActiveSupport::TestCase
  setup do
    @prompt = prompts(:doc_summarizer)
    @experiment = Experiment.create!(
      prompt: @prompt, name: "bayes-test",
      variant_a_version: prompt_versions(:doc_summarizer_production),
      variant_b_version: prompt_versions(:doc_summarizer_dev),
      status: :running, started_at: Time.current
    )
  end

  test "returns nil with insufficient data" do
    result = Experiments::BayesianSignificance.call(experiment: @experiment)
    assert_nil result
  end

  test "detects clear winner with sufficient data" do
    log = Log.create!(prompt: @prompt, prompt_version: prompt_versions(:doc_summarizer_production), project: projects(:playground), output: "test")

    50.times do |i|
      ExperimentResult.create!(experiment: @experiment, log: log, variant: "a", score: rand(0.3..0.5))
      ExperimentResult.create!(experiment: @experiment, log: log, variant: "b", score: rand(0.8..0.95))
    end

    result = Experiments::BayesianSignificance.call(experiment: @experiment)
    assert_not_nil result
    assert result[:prob_b_wins] > 0.9
    assert_equal :b, result[:winner]
  end

  test "no winner when results are close" do
    log = Log.create!(prompt: @prompt, prompt_version: prompt_versions(:doc_summarizer_production), project: projects(:playground), output: "test")

    50.times do
      ExperimentResult.create!(experiment: @experiment, log: log, variant: "a", score: rand(0.45..0.65))
      ExperimentResult.create!(experiment: @experiment, log: log, variant: "b", score: rand(0.45..0.65))
    end

    result = Experiments::BayesianSignificance.call(experiment: @experiment)
    assert_not_nil result
    assert_nil result[:winner]
  end
end
