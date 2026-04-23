class ScoreOutputJob < ApplicationJob
  queue_as :default

  retry_on Faraday::Error, wait: :polynomially_longer, attempts: 5
  discard_on ActiveRecord::RecordNotFound

  def perform(log_id:, scorer_id:)
    log = Log.find(log_id)
    scorer = Scorer.find(scorer_id)

    # Idempotency: a previous attempt of this job may have scored the log
    # and crashed before updating the ExperimentResult. Re-running then
    # would double-score. Early return is safe because scores are final.
    return if log.score.present?

    if scorer.type_llm_judge? && ENV["OPENAI_API_KEY"].blank?
      log.update_columns(score_rationale: "scoring_disabled: OPENAI_API_KEY not configured", scorer_id: scorer.id)
      return
    end

    score, rationale = Scoring::Evaluate.call(
      scorer: scorer,
      prompt_content: log.prompt_version.content,
      input_vars: log.input_vars,
      output: log.output
    )

    # Wrap the two writes in a transaction so we never end up with a
    # scored Log but an unscored ExperimentResult.
    ActiveRecord::Base.transaction do
      log.update!(score: score, score_rationale: rationale, scorer_id: scorer.id)

      if log.experiment_id.present?
        ExperimentResult.where(log_id: log.id).update_all(score: score)
      end
    end
  end
end
