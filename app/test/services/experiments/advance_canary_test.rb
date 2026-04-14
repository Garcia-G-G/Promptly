require "test_helper"

class Experiments::AdvanceCanaryTest < ActiveSupport::TestCase
  setup do
    @experiment = Experiment.create!(
      prompt: prompts(:doc_summarizer), name: "canary-test",
      variant_a_version: prompt_versions(:doc_summarizer_production),
      variant_b_version: prompt_versions(:doc_summarizer_dev),
      status: :running, started_at: Time.current, canary_stage: 1
    )
  end

  test "advances canary stage" do
    Experiments::AdvanceCanary.call(experiment: @experiment, to: 10)
    assert_equal 10, @experiment.canary_stage
  end

  test "cannot go backwards" do
    @experiment.update!(canary_stage: 50)
    assert_raises ArgumentError do
      Experiments::AdvanceCanary.call(experiment: @experiment, to: 10)
    end
  end

  test "cannot advance if not running" do
    @experiment.update!(status: :paused)
    assert_raises ArgumentError do
      Experiments::AdvanceCanary.call(experiment: @experiment, to: 50)
    end
  end

  test "rejects invalid canary stage" do
    assert_raises ArgumentError do
      Experiments::AdvanceCanary.call(experiment: @experiment, to: 25)
    end
  end
end
