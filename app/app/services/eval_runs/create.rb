module EvalRuns
  class Create
    def self.call(prompt_version:, dataset:, scorer:, pass_threshold: 0.6)
      eval_run = EvalRun.create!(
        prompt_version: prompt_version,
        dataset: dataset,
        scorer: scorer,
        status: :queued,
        pass_threshold: pass_threshold,
        total_rows: dataset.dataset_rows.count
      )

      RunEvalJob.perform_later(eval_run_id: eval_run.id)
      eval_run
    end
  end
end
