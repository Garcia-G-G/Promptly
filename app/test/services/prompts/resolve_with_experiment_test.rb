require "test_helper"

class Prompts::ResolveWithExperimentTest < ActiveSupport::TestCase
  setup do
    @project = projects(:playground)
    @prompt = prompts(:doc_summarizer)
    @v_prod = prompt_versions(:doc_summarizer_production)
    @v_dev = prompt_versions(:doc_summarizer_dev)
  end

  test "no experiment returns baseline" do
    result = Prompts::Resolve.call(project: @project, slug: "doc-summarizer")
    assert_equal :baseline, result[:source]
    assert_nil result[:experiment]
    assert_nil result[:variant]
  end

  test "experiment with no request_id returns baseline" do
    Experiment.create!(prompt: @prompt, name: "no-req-id",
      variant_a_version: @v_prod, variant_b_version: @v_dev,
      status: :running, started_at: Time.current)

    result = Prompts::Resolve.call(project: @project, slug: "doc-summarizer")
    assert_equal :baseline, result[:source]
  end

  test "experiment with request_id routes through experiment" do
    exp = Experiment.create!(prompt: @prompt, name: "with-req-id",
      variant_a_version: @v_prod, variant_b_version: @v_dev,
      status: :running, started_at: Time.current)

    result = Prompts::Resolve.call(project: @project, slug: "doc-summarizer", request_id: "test-req-1")
    assert_equal :experiment, result[:source]
    assert_equal exp, result[:experiment]
    assert_includes [ :a, :b ], result[:variant]
  end

  test "canary experiment can return not_in_canary" do
    Experiment.create!(prompt: @prompt, name: "canary-test",
      variant_a_version: @v_prod, variant_b_version: @v_dev,
      status: :running, started_at: Time.current, canary_stage: 1)

    sources = 100.times.map { |i|
      Prompts::Resolve.call(project: @project, slug: "doc-summarizer", request_id: "canary-req-#{i}")[:source]
    }
    assert_includes sources, :not_in_canary
  end
end
