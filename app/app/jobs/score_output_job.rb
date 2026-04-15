# frozen_string_literal: true

class ScoreOutputJob < ApplicationJob
  queue_as :default

  retry_on Anthropic::Errors::APIError, wait: :polynomially_longer, attempts: 5
  discard_on ActiveRecord::RecordNotFound

  def perform(log_id:, scorer_id:)
    log = Log.find(log_id)
    scorer = Scorer.find(scorer_id)

    # Idempotent: skip if already scored
    return if log.score.present?

    # Check API key for LLM judge
    if scorer.type_llm_judge? && ENV["ANTHROPIC_API_KEY"].blank?
      log.update_columns(
        score_rationale: "scoring_disabled: ANTHROPIC_API_KEY not configured",
        scorer_id: scorer.id
      )
      return
    end

    score, rationale = case scorer.scorer_type
    when "llm_judge"
      score_with_llm(log, scorer)
    when "exact_match"
      score_exact_match(log, scorer)
    when "regex"
      score_regex(log, scorer)
    else
      [ nil, "unsupported scorer type: #{scorer.scorer_type}" ]
    end

    # Update log
    log.update_columns(score: score, score_rationale: rationale, scorer_id: scorer.id)

    # Update experiment result if present
    if log.experiment_id.present?
      ExperimentResult.where(log_id: log.id).update_all(score: score)
    end
  end

  private

  def score_with_llm(log, scorer)
    client = Anthropic::Client.new(api_key: ENV.fetch("ANTHROPIC_API_KEY"))

    response = client.messages.create(
      model: scorer.model_hint || PromptVersion::DEFAULT_MODEL_HINT,
      max_tokens: 256,
      system_: scorer.content,
      messages: [
        {
          role: "user",
          content: <<~MSG
            Prompt used:
            #{log.prompt_version.content}

            Variables provided:
            #{log.input_vars.to_json}

            Output received:
            #{log.output}
          MSG
        }
      ]
    )

    text = response.content.first.text
    parsed = JSON.parse(text)
    score = parsed["score"].to_f.clamp(0.0, 1.0)
    rationale = parsed["rationale"].to_s

    [ score, rationale ]
  rescue JSON::ParserError => e
    # Don't retry JSON parse errors — response is malformed
    [ nil, "scoring_error: #{e.message}" ]
  end

  def score_exact_match(log, scorer)
    match = log.output.strip == scorer.content.to_s.strip
    [ match ? 1.0 : 0.0, match ? "exact match" : "no match" ]
  end

  def score_regex(log, scorer)
    pattern = Regexp.new(scorer.content.to_s)
    match = pattern.match?(log.output)
    [ match ? 1.0 : 0.0, match ? "regex matched" : "regex did not match" ]
  rescue RegexpError => e
    [ nil, "invalid regex: #{e.message}" ]
  end
end
