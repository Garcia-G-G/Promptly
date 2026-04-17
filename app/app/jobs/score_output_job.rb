class ScoreOutputJob < ApplicationJob
  queue_as :default

  retry_on Anthropic::Errors::APIError, wait: :polynomially_longer, attempts: 5
  discard_on ActiveRecord::RecordNotFound

  def perform(log_id:, scorer_id:)
    log = Log.find(log_id)
    scorer = Scorer.find(scorer_id)

    return if log.score.present?

    if scorer.type_llm_judge? && ENV["ANTHROPIC_API_KEY"].blank?
      log.update_columns(score_rationale: "scoring_disabled: ANTHROPIC_API_KEY not configured", scorer_id: scorer.id)
      return
    end

    score, rationale = Scoring::Evaluate.call(
      scorer: scorer,
      prompt_content: log.prompt_version.content,
      input_vars: log.input_vars,
      output: log.output
    )

    log.update_columns(score: score, score_rationale: rationale, scorer_id: scorer.id)

    if log.experiment_id.present?
      ExperimentResult.where(log_id: log.id).update_all(score: score)
    end
  end
end
