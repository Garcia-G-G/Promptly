module Serializers
  class EvalRunSerializer
    def self.call(eval_run, include_results: false)
      data = {
        id: eval_run.id,
        prompt_version_id: eval_run.prompt_version_id,
        dataset_id: eval_run.dataset_id,
        scorer_id: eval_run.scorer_id,
        status: eval_run.status,
        aggregate_score: eval_run.aggregate_score,
        pass_rate: eval_run.pass_rate,
        pass_threshold: eval_run.pass_threshold,
        total_rows: eval_run.total_rows,
        scored_rows: eval_run.scored_rows,
        started_at: eval_run.started_at&.iso8601,
        finished_at: eval_run.finished_at&.iso8601,
        error_message: eval_run.error_message,
        created_at: eval_run.created_at.iso8601
      }

      if include_results
        data[:results] = eval_run.eval_run_results.map do |r|
          {
            id: r.id,
            dataset_row_id: r.dataset_row_id,
            output: r.output,
            score: r.score,
            score_rationale: r.score_rationale,
            latency_ms: r.latency_ms,
            error_message: r.error_message
          }
        end
      end

      data
    end
  end
end
