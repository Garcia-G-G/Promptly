require "test_helper"

class ExperimentTest < ActiveSupport::TestCase
  setup do
    @prompt = prompts(:doc_summarizer)
    @v_prod = prompt_versions(:doc_summarizer_production)
    @v_dev = prompt_versions(:doc_summarizer_dev)
  end

  test "valid experiment" do
    exp = Experiment.new(
      prompt: @prompt, name: "test-exp",
      variant_a_version: @v_prod, variant_b_version: @v_dev,
      traffic_split: 50, environment: "production"
    )
    assert exp.valid?
  end

  test "requires name" do
    exp = Experiment.new(prompt: @prompt, name: nil, variant_a_version: @v_prod, variant_b_version: @v_dev)
    assert_not exp.valid?
  end

  test "name unique per prompt" do
    Experiment.create!(prompt: @prompt, name: "unique-name", variant_a_version: @v_prod, variant_b_version: @v_dev)
    dup = Experiment.new(prompt: @prompt, name: "unique-name", variant_a_version: @v_prod, variant_b_version: @v_dev)
    assert_not dup.valid?
  end

  test "traffic_split must be between 1 and 99" do
    [ 0, 100, -1 ].each do |bad|
      exp = Experiment.new(prompt: @prompt, name: "ts-#{bad}", variant_a_version: @v_prod, variant_b_version: @v_dev, traffic_split: bad)
      assert_not exp.valid?, "Expected traffic_split #{bad} to be invalid"
    end
  end

  test "variants must belong to same prompt" do
    other_prompt = Prompt.create!(project: projects(:playground), slug: "other-prompt")
    other_version = PromptVersion.create!(prompt: other_prompt, content: "other", created_via: :api,
      version_number: 1, content_hash: Digest::SHA256.hexdigest("other"))

    exp = Experiment.new(prompt: @prompt, name: "cross-prompt", variant_a_version: @v_prod, variant_b_version: other_version)
    assert_not exp.valid?
    assert_includes exp.errors[:base].join, "same prompt"
  end

  test "variants must differ" do
    exp = Experiment.new(prompt: @prompt, name: "same-variant", variant_a_version: @v_prod, variant_b_version: @v_prod)
    assert_not exp.valid?
    assert_includes exp.errors[:base].join, "different"
  end

  test "canary_stage must be in allowed set" do
    exp = Experiment.new(prompt: @prompt, name: "bad-canary", variant_a_version: @v_prod, variant_b_version: @v_dev, canary_stage: 25)
    assert_not exp.valid?
  end

  test "allowed canary stages" do
    [ 1, 10, 50, 100 ].each do |stage|
      exp = Experiment.new(prompt: @prompt, name: "canary-#{stage}", variant_a_version: @v_prod, variant_b_version: @v_dev, canary_stage: stage)
      assert exp.valid?, "Expected canary_stage #{stage} to be valid"
    end
  end

  test "null canary_stage is valid" do
    exp = Experiment.new(prompt: @prompt, name: "no-canary", variant_a_version: @v_prod, variant_b_version: @v_dev, canary_stage: nil)
    assert exp.valid?
  end

  test "partial unique index prevents two running experiments on same prompt+env" do
    Experiment.create!(prompt: @prompt, name: "first-running", variant_a_version: @v_prod, variant_b_version: @v_dev, status: :running, started_at: Time.current)
    assert_raises ActiveRecord::RecordNotUnique do
      Experiment.create!(prompt: @prompt, name: "second-running", variant_a_version: @v_prod, variant_b_version: @v_dev, status: :running, started_at: Time.current)
    end
  end

  test "two draft experiments on same prompt+env is allowed" do
    Experiment.create!(prompt: @prompt, name: "draft-1", variant_a_version: @v_prod, variant_b_version: @v_dev, status: :draft)
    exp2 = Experiment.create!(prompt: @prompt, name: "draft-2", variant_a_version: @v_prod, variant_b_version: @v_dev, status: :draft)
    assert exp2.persisted?
  end
end
