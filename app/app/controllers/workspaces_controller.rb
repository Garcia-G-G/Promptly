class WorkspacesController < ApplicationController
  def new
    @workspace = Workspace.new
  end

  def create
    @workspace = Workspace.new(workspace_params)
    @workspace.owner = current_user

    ActiveRecord::Base.transaction do
      if @workspace.save
        Membership.create!(workspace: @workspace, user: current_user, role: :owner)
        redirect_to workspace_path(@workspace.slug), notice: "Workspace created."
      else
        render :new, status: :unprocessable_entity
      end
    end
  end

  def show
    @workspace = current_workspace
    @projects = @workspace.projects.order(:name)
    @prompts = Prompt.joins(:project)
      .where(projects: { workspace_id: @workspace.id })
      .includes(:prompt_versions, :project)
      .order(updated_at: :desc)
      .limit(10)

    @experiments = Experiment.joins(prompt: { project: :workspace })
      .where(workspaces: { id: @workspace.id })
      .where(status: :running)
      .includes(prompt: :project)
      .limit(5)

    log_scope = Log.joins(project: :workspace).where(workspaces: { id: @workspace.id })
    recent_logs = log_scope.where("logs.created_at > ?", 24.hours.ago)
    @recent_logs_count = recent_logs.count
    @avg_score = recent_logs.where.not(score: nil).average(:score)&.round(2)
    @p95_latency = compute_p95_latency(recent_logs)
  end

  private

  def workspace_params
    params.require(:workspace).permit(:name, :slug)
  end

  # Simple p95 using offset — fine for the modest log volumes the
  # dashboard previews. We keep it on the logs subquery so it's always
  # scoped to the 24h window.
  def compute_p95_latency(scope)
    count = scope.where.not(latency_ms: nil).count
    return nil if count.zero?

    offset = [ (count * 0.95).floor - 1, 0 ].max
    scope.where.not(latency_ms: nil).order(:latency_ms).offset(offset).limit(1).pick(:latency_ms)
  end
end
