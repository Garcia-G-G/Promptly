module Web
  class EvalRunsController < Web::BaseController
    def index
      @eval_runs = EvalRun.joins(dataset: { project: :workspace })
        .where(workspaces: { id: @workspace.id })
        .includes(:dataset, prompt_version: :prompt)
        .order(created_at: :desc)
        .limit(50)
    end
  end
end
