class RunEvalJob < ApplicationJob
  queue_as :evaluations

  retry_on Faraday::Error, wait: :polynomially_longer, attempts: 3
  discard_on ActiveRecord::RecordNotFound

  def perform(eval_run_id:)
    eval_run = EvalRun.find(eval_run_id)
    return if eval_run.done? || eval_run.failed?

    eval_run.update!(status: :running, started_at: Time.current)

    prompt_content = eval_run.prompt_version.content
    scorer = eval_run.scorer

    # Exclude already-processed rows via subquery so retries don't load
    # the full row-id set into Ruby memory for large datasets.
    completed_row_ids = EvalRunResult.where(eval_run_id: eval_run.id).select(:dataset_row_id)
    pending_rows = eval_run.dataset.dataset_rows.where.not(id: completed_row_ids)

    pending_rows.find_each(batch_size: 100) do |row|
      process_row(eval_run, row, prompt_content, scorer)
    end

    EvalRuns::Complete.call(eval_run: eval_run)
  rescue StandardError => e
    eval_run&.update!(status: :failed, error_message: e.message, finished_at: Time.current)
    raise if e.is_a?(Faraday::Error)
  end

  private

  def process_row(eval_run, row, prompt_content, scorer)
    interpolated = interpolate(prompt_content, row.input_vars)
    output = generate_output(interpolated, eval_run.prompt_version.model_hint)

    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    score, rationale = Scoring::Evaluate.call(
      scorer: scorer,
      prompt_content: prompt_content,
      input_vars: row.input_vars,
      output: output || "generation_failed"
    )
    latency = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000).to_i

    EvalRunResult.create!(
      eval_run: eval_run,
      dataset_row: row,
      output: output,
      score: score,
      score_rationale: rationale,
      latency_ms: latency
    )
  rescue StandardError => e
    EvalRunResult.create!(
      eval_run: eval_run,
      dataset_row: row,
      error_message: e.message
    )
  end

  def generate_output(prompt_content, model_hint)
    return nil if ENV["OPENAI_API_KEY"].blank?

    client = OpenAI::Client.new(access_token: ENV.fetch("OPENAI_API_KEY"))
    response = client.chat(
      parameters: {
        model: model_hint || PromptVersion::DEFAULT_MODEL_HINT,
        max_tokens: 1024,
        messages: [ { role: "user", content: prompt_content } ]
      }
    )
    response.dig("choices", 0, "message", "content")
  rescue StandardError => e
    Rails.logger.warn("RunEvalJob generate_output failed: #{e.message}")
    nil
  end

  def interpolate(content, vars)
    result = content.dup
    vars.each { |key, value| result.gsub!("{#{key}}", value.to_s) }
    result
  end
end
