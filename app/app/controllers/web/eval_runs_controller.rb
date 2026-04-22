module Web
  class EvalRunsController < Web::BaseController
    def index
      scope = EvalRun.joins(prompt_version: { prompt: { project: :workspace } })
        .where(workspaces: { id: @workspace.id })
        .includes(prompt_version: { prompt: :project }, dataset: [], scorer: [])
        .order(created_at: :desc)
        .limit(50)

      scope = scope.where(prompt_versions: { prompt_id: params[:prompt_id] }) if params[:prompt_id].present?
      scope = scope.where(dataset_id: params[:dataset_id]) if params[:dataset_id].present?
      scope = scope.where(status: params[:status]) if params[:status].present?

      @eval_runs = scope
      @prompts = Prompt.joins(:project).where(projects: { workspace_id: @workspace.id }).order(:slug)
      @datasets = Dataset.joins(:project).where(projects: { workspace_id: @workspace.id }).order(:name)
    end

    def show
      @eval_run = EvalRun.joins(prompt_version: { prompt: { project: :workspace } })
        .where(workspaces: { id: @workspace.id })
        .includes(prompt_version: { prompt: :project },
                  dataset: [], scorer: [],
                  eval_run_results: :dataset_row)
        .find(params[:id])

      @results = @eval_run.eval_run_results.includes(:dataset_row).order(:id)
      @avg_latency = @results.where.not(latency_ms: nil).average(:latency_ms)&.round
    end

    def new
      @prompts = Prompt.joins(:project)
        .where(projects: { workspace_id: @workspace.id })
        .includes(:prompt_versions).order(:slug)
      @datasets = Dataset.joins(:project)
        .where(projects: { workspace_id: @workspace.id }).order(:name)
      @scorers = Scorer.joins(:project)
        .where(projects: { workspace_id: @workspace.id })
        .active.order(:name)
    end

    def create
      prompt_version = PromptVersion.joins(prompt: { project: :workspace })
        .where(workspaces: { id: @workspace.id })
        .find(params.dig(:eval_run, :prompt_version_id))
      dataset = Dataset.joins(:project)
        .where(projects: { workspace_id: @workspace.id })
        .find(params.dig(:eval_run, :dataset_id))
      scorer = Scorer.joins(:project)
        .where(projects: { workspace_id: @workspace.id })
        .find(params.dig(:eval_run, :scorer_id))

      threshold = (params.dig(:eval_run, :pass_threshold) || 0.6).to_f

      eval_run = EvalRuns::Create.call(
        prompt_version: prompt_version,
        dataset: dataset,
        scorer: scorer,
        pass_threshold: threshold
      )

      redirect_to workspace_web_eval_run_path(@workspace.slug, eval_run),
        notice: "Eval run ##{eval_run.id} queued."
    rescue ActiveRecord::RecordNotFound => e
      redirect_to new_workspace_web_eval_run_path(@workspace.slug),
        alert: "Invalid selection: #{e.message}"
    rescue ActiveRecord::RecordInvalid => e
      redirect_to new_workspace_web_eval_run_path(@workspace.slug), alert: e.message
    end
  end
end
