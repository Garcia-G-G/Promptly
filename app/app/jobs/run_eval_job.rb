class RunEvalJob < ApplicationJob
  queue_as :default

  retry_on Anthropic::Errors::APIError, wait: :polynomially_longer, attempts: 3
  discard_on ActiveRecord::RecordNotFound

  def perform(eval_run_id:)
    eval_run = EvalRun.find(eval_run_id)
    return if eval_run.done? || eval_run.failed?

    eval_run.update!(status: :running, started_at: Time.current)

    prompt_content = eval_run.prompt_version.content
    scorer = eval_run.scorer

    eval_run.dataset.dataset_rows.find_each.each_slice(10) do |batch|
      batch.each do |row|
        process_row(eval_run, row, prompt_content, scorer)
      end
    end

    EvalRuns::Complete.call(eval_run: eval_run)
  rescue => e
    eval_run&.update!(status: :failed, error_message: e.message, finished_at: Time.current)
    raise if e.is_a?(Anthropic::Errors::APIError)
  end

  private

  def process_row(eval_run, row, prompt_content, scorer)
    interpolated = interpolate(prompt_content, row.input_vars)

    # For eval, we generate output using the prompt then score it
    # But since we may not have an API key, handle gracefully
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
  rescue => e
    EvalRunResult.create!(
      eval_run: eval_run,
      dataset_row: row,
      error_message: e.message
    )
  end

  def generate_output(prompt_content, model_hint)
    return nil if ENV["ANTHROPIC_API_KEY"].blank?

    client = Anthropic::Client.new(api_key: ENV.fetch("ANTHROPIC_API_KEY"))
    response = client.messages.create(
      model: model_hint || PromptVersion::DEFAULT_MODEL_HINT,
      max_tokens: 1024,
      messages: [ { role: "user", content: prompt_content } ]
    )
    response.content.first.text
  rescue => e
    Rails.logger.warn("RunEvalJob generate_output failed: #{e.message}")
    nil
  end

  def interpolate(content, vars)
    result = content.dup
    vars.each do |key, value|
      result.gsub!("{#{key}}", value.to_s)
    end
    result
  end
end
