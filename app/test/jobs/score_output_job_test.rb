require "test_helper"

class ScoreOutputJobTest < ActiveJob::TestCase
  setup do
    @log = Log.create!(
      prompt: prompts(:doc_summarizer),
      prompt_version: prompt_versions(:doc_summarizer_production),
      project: projects(:playground),
      output: "This is a great summary with 3 bullet points."
    )
  end

  test "exact_match scorer scores 1.0 on match" do
    scorer = scorers(:exact_match_scorer)
    log = Log.create!(
      prompt: prompts(:doc_summarizer),
      prompt_version: prompt_versions(:doc_summarizer_production),
      project: projects(:playground),
      output: "expected output"
    )

    ScoreOutputJob.perform_now(log_id: log.id, scorer_id: scorer.id)
    log.reload
    assert_equal 1.0, log.score
    assert_equal "exact match", log.score_rationale
    assert_equal scorer.id, log.scorer_id
  end

  test "exact_match scorer scores 0.0 on mismatch" do
    scorer = scorers(:exact_match_scorer)
    ScoreOutputJob.perform_now(log_id: @log.id, scorer_id: scorer.id)
    @log.reload
    assert_equal 0.0, @log.score
    assert_equal "no match", @log.score_rationale
  end

  test "regex scorer scores 1.0 on match" do
    scorer = scorers(:regex_scorer)
    log = Log.create!(
      prompt: prompts(:doc_summarizer),
      prompt_version: prompt_versions(:doc_summarizer_production),
      project: projects(:playground),
      output: "Here are 3 bullets of content"
    )

    ScoreOutputJob.perform_now(log_id: log.id, scorer_id: scorer.id)
    log.reload
    assert_equal 1.0, log.score
  end

  test "regex scorer scores 0.0 on mismatch" do
    scorer = scorers(:regex_scorer)
    log = Log.create!(
      prompt: prompts(:doc_summarizer),
      prompt_version: prompt_versions(:doc_summarizer_production),
      project: projects(:playground),
      output: "No numeric bullet patterns here"
    )

    ScoreOutputJob.perform_now(log_id: log.id, scorer_id: scorer.id)
    log.reload
    assert_equal 0.0, log.score
    assert_equal "regex did not match", log.score_rationale
  end

  test "idempotent — skips already scored log" do
    scorer = scorers(:exact_match_scorer)
    @log.update_columns(score: 0.5, score_rationale: "already scored")

    ScoreOutputJob.perform_now(log_id: @log.id, scorer_id: scorer.id)
    @log.reload
    assert_equal 0.5, @log.score  # unchanged
    assert_equal "already scored", @log.score_rationale  # unchanged
  end

  test "updates experiment_result score" do
    scorer = scorers(:exact_match_scorer)
    exp = Experiment.create!(
      prompt: prompts(:doc_summarizer), name: "score-exp",
      variant_a_version: prompt_versions(:doc_summarizer_production),
      variant_b_version: prompt_versions(:doc_summarizer_dev),
      status: :running, started_at: Time.current
    )
    @log.update_columns(experiment_id: exp.id, variant: "a")
    ExperimentResult.create!(experiment: exp, log: @log, variant: "a")

    ScoreOutputJob.perform_now(log_id: @log.id, scorer_id: scorer.id)

    er = ExperimentResult.find_by(log_id: @log.id)
    assert_equal 0.0, er.score  # exact_match mismatch
  end

  test "missing API key sets rationale for llm_judge" do
    scorer = scorers(:default_quality)

    ScoreOutputJob.perform_now(log_id: @log.id, scorer_id: scorer.id)
    @log.reload
    assert_includes @log.score_rationale, "scoring_disabled"
  end

  test "discards when log not found" do
    assert_nothing_raised do
      ScoreOutputJob.perform_now(log_id: -1, scorer_id: scorers(:exact_match_scorer).id)
    end
  end
end
