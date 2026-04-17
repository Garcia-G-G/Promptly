require "test_helper"

class ScorerTest < ActiveSupport::TestCase
  test "valid scorer" do
    scorer = Scorer.new(project: projects(:playground), name: "new-scorer", scorer_type: :llm_judge)
    assert scorer.valid?
  end

  test "name unique per project" do
    assert_raises ActiveRecord::RecordInvalid do
      Scorer.create!(project: projects(:playground), name: "default-quality", scorer_type: :llm_judge)
    end
  end

  test "scorer_type enum" do
    scorer = scorers(:default_quality)
    assert scorer.type_llm_judge?
  end

  test "active scope" do
    active = Scorer.active
    assert active.all? { |s| s.active? }
  end
end
