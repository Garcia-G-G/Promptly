module EvalRuns
  class Complete
    def self.call(eval_run:)
      results = eval_run.eval_run_results.where.not(score: nil)
      scored_count = results.count

      if scored_count > 0
        scores = results.pluck(:score)
        aggregate = scores.sum / scores.size.to_f
        pass_count = scores.count { |s| s >= eval_run.pass_threshold }
        pass_rate = pass_count.to_f / scored_count
      else
        aggregate = nil
        pass_rate = nil
      end

      eval_run.update!(
        status: :done,
        aggregate_score: aggregate,
        pass_rate: pass_rate,
        scored_rows: scored_count,
        finished_at: Time.current
      )
    end
  end
end
