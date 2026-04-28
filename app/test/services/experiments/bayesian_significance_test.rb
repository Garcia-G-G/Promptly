require "test_helper"

class Experiments::BayesianSignificanceTest < ActiveSupport::TestCase
  # Seeded so the test isn't flaky — the service samples deterministically
  # via Random.new(42) once it's been called, but the test fixtures used
  # to come from global rand which made `no winner when results are close`
  # tip toward :a or :b based on stdlib RNG state.
  setup do
    @prompt = prompts(:doc_summarizer)
    @experiment = Experiment.create!(
      prompt: @prompt, name: "bayes-test",
      variant_a_version: prompt_versions(:doc_summarizer_production),
      variant_b_version: prompt_versions(:doc_summarizer_dev),
      status: :running, started_at: Time.current
    )
    @rng = Random.new(20260428)
  end

  def sample(range)
    range.first + @rng.rand * (range.last - range.first)
  end

  test "returns nil with insufficient data" do
    result = Experiments::BayesianSignificance.call(experiment: @experiment)
    assert_nil result
  end

  test "detects clear winner with sufficient data" do
    log = Log.create!(prompt: @prompt, prompt_version: prompt_versions(:doc_summarizer_production), project: projects(:playground), output: "test")

    50.times do
      ExperimentResult.create!(experiment: @experiment, log: log, variant: "a", score: sample(0.3..0.5))
      ExperimentResult.create!(experiment: @experiment, log: log, variant: "b", score: sample(0.8..0.95))
    end

    result = Experiments::BayesianSignificance.call(experiment: @experiment)
    assert_not_nil result
    assert result[:prob_b_wins] > 0.9
    assert_equal :b, result[:winner]
  end

  test "no winner when results are identical" do
    # Identical means → no statistical signal in either direction. Using
    # a fixed score (rather than rand) keeps the assertion deterministic
    # regardless of the test runner's seed.
    log = Log.create!(prompt: @prompt, prompt_version: prompt_versions(:doc_summarizer_production), project: projects(:playground), output: "test")

    50.times do
      ExperimentResult.create!(experiment: @experiment, log: log, variant: "a", score: 0.55)
      ExperimentResult.create!(experiment: @experiment, log: log, variant: "b", score: 0.55)
    end

    result = Experiments::BayesianSignificance.call(experiment: @experiment)
    assert_not_nil result
    assert_nil result[:winner]
  end
end
