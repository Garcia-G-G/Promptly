require "test_helper"

class CheckCanaryRollbackJobTest < ActiveJob::TestCase
  test "enqueues without error" do
    assert_nothing_raised do
      CheckCanaryRollbackJob.perform_later
    end
  end

  test "runs inline without raising when no experiments match" do
    Experiment.update_all(status: :draft)
    assert_nothing_raised do
      CheckCanaryRollbackJob.perform_now
    end
  end
end
