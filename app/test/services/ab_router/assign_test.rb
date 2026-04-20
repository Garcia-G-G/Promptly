require "test_helper"

class AbRouter::AssignTest < ActiveSupport::TestCase
  setup do
    @prompt = prompts(:doc_summarizer)
    @v_prod = prompt_versions(:doc_summarizer_production)
    @v_dev = prompt_versions(:doc_summarizer_dev)
    @experiment = Experiment.create!(
      prompt: @prompt, name: "assign-test",
      variant_a_version: @v_prod, variant_b_version: @v_dev,
      traffic_split: 50, status: :running, started_at: Time.current
    )
  end

  test "deterministic assignment for same request_id" do
    result1 = AbRouter::Assign.call(experiment: @experiment, request_id: "req-123")
    result2 = AbRouter::Assign.call(experiment: @experiment, request_id: "req-123")
    assert_equal result1, result2
  end

  test "returns :a or :b" do
    result = AbRouter::Assign.call(experiment: @experiment, request_id: "req-abc")
    assert_includes [ :a, :b ], result
  end

  test "sticky session returns same variant" do
    first = AbRouter::Assign.call(experiment: @experiment, request_id: "sticky-test")
    second = AbRouter::Assign.call(experiment: @experiment, request_id: "sticky-test")
    assert_equal first, second
  end

  test "increments counters in Redis" do
    AbRouter::Assign.call(experiment: @experiment, request_id: "counter-test-1")
    AbRouter::Assign.call(experiment: @experiment, request_id: "counter-test-2")

    counts = AbRouter::Counts.call(experiment: @experiment)
    assert_equal 2, counts[:a] + counts[:b]
  end

  test "canary gate rejects traffic outside canary percentage" do
    @experiment.update!(canary_stage: 1)

    results = 100.times.map { |i| AbRouter::Assign.call(experiment: @experiment, request_id: "canary-#{i}") }
    not_in_canary_count = results.count(:not_in_canary)

    # With canary_stage=1, ~99% should be :not_in_canary
    assert not_in_canary_count > 90, "Expected most requests to be outside canary, got #{not_in_canary_count}"
  end

  test "canary gate at 100 lets all traffic through" do
    @experiment.update!(canary_stage: 100)

    results = 20.times.map { |i| AbRouter::Assign.call(experiment: @experiment, request_id: "full-canary-#{i}") }
    assert_equal 0, results.count(:not_in_canary)
  end

  test "no canary_stage lets all traffic through" do
    results = 20.times.map { |i| AbRouter::Assign.call(experiment: @experiment, request_id: "no-canary-#{i}") }
    assert_equal 0, results.count(:not_in_canary)
  end

  test "Redis failure falls back to deterministic hash" do
    original_pool = Promptly::Redis.instance_variable_get(:@pool)
    begin
      bad_pool = Object.new
      bad_pool.define_singleton_method(:with) do |&_block|
        raise ::Redis::CannotConnectError, "simulated failure"
      end
      Promptly::Redis.instance_variable_set(:@pool, bad_pool)

      result = AbRouter::Assign.call(experiment: @experiment, request_id: "fallback-test")
      assert_includes [ :a, :b, :not_in_canary ], result
    ensure
      Promptly::Redis.instance_variable_set(:@pool, original_pool)
    end
  end
end
