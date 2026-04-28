require "test_helper"

class EvaluateExperimentsJobTest < ActiveJob::TestCase
  test "processes running experiments without raising" do
    assert_nothing_raised do
      EvaluateExperimentsJob.perform_now
    end
  end

  test "skips experiments with no significance signal" do
    experiment = experiments(:tone_tweak)
    experiment.update!(status: :running, started_at: Time.current)

    assert_nothing_raised do
      EvaluateExperimentsJob.perform_now
    end

    # No results → no winner → status remains running
    assert_equal "running", experiment.reload.status
  end
end
