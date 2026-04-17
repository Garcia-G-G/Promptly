require "test_helper"

class Experiments::UpdateStatusTest < ActiveSupport::TestCase
  setup do
    @experiment = Experiment.create!(
      prompt: prompts(:doc_summarizer), name: "status-test",
      variant_a_version: prompt_versions(:doc_summarizer_production),
      variant_b_version: prompt_versions(:doc_summarizer_dev),
      status: :draft
    )
  end

  test "draft to running sets started_at" do
    Experiments::UpdateStatus.call(experiment: @experiment, status: :running)
    assert @experiment.running?
    assert_not_nil @experiment.started_at
  end

  test "running to paused" do
    @experiment.update!(status: :running, started_at: Time.current)
    Experiments::UpdateStatus.call(experiment: @experiment, status: :paused)
    assert @experiment.paused?
  end

  test "running to concluded sets concluded_at" do
    @experiment.update!(status: :running, started_at: Time.current)
    Experiments::UpdateStatus.call(experiment: @experiment, status: :concluded, winner_version_id: prompt_versions(:doc_summarizer_production).id)
    assert @experiment.concluded?
    assert_not_nil @experiment.concluded_at
    assert_equal prompt_versions(:doc_summarizer_production).id, @experiment.winner_version_id
  end

  test "cannot start a concluded experiment" do
    @experiment.update!(status: :concluded, started_at: 1.hour.ago, concluded_at: Time.current)
    assert_raises ArgumentError do
      Experiments::UpdateStatus.call(experiment: @experiment, status: :running)
    end
  end

  test "cannot pause a draft" do
    assert_raises ArgumentError do
      Experiments::UpdateStatus.call(experiment: @experiment, status: :paused)
    end
  end
end
