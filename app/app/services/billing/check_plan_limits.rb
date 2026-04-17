module Billing
  class CheckPlanLimits
    PLAN_LIMITS = {
      "starter" => { sdk_calls: 50_000, projects: 5, experiments: 3, eval_runs: 100 },
      "pro" => { sdk_calls: 500_000, projects: Float::INFINITY, experiments: Float::INFINITY, eval_runs: Float::INFINITY },
      "free" => { sdk_calls: 1_000, projects: 1, experiments: 0, eval_runs: 10 }
    }.freeze

    def self.call(workspace:, resource:)
      limits = PLAN_LIMITS[workspace.plan] || PLAN_LIMITS["free"]
      limit = limits[resource]

      return { allowed: true, limit: limit, current: 0 } if limit == Float::INFINITY

      current = current_usage(workspace, resource)
      { allowed: current < limit, limit: limit, current: current, remaining: [ limit - current, 0 ].max }
    end

    def self.current_usage(workspace, resource)
      period_start = billing_period_start(workspace)
      case resource
      when :sdk_calls
        Log.joins(project: :workspace).where(workspaces: { id: workspace.id }).where("logs.created_at >= ?", period_start).count
      when :projects
        workspace.projects.count
      when :experiments
        Experiment.joins(prompt: { project: :workspace }).where(workspaces: { id: workspace.id }).where(status: :running).count
      when :eval_runs
        EvalRun.joins(prompt_version: { prompt: { project: :workspace } }).where(workspaces: { id: workspace.id }).where("eval_runs.created_at >= ?", period_start).count
      else
        0
      end
    end

    def self.billing_period_start(workspace)
      today = Date.current
      day = workspace.created_at&.day || 1
      start = Date.new(today.year, today.month, [ day, today.end_of_month.day ].min)
      start > today ? start.prev_month : start
    end

    private_class_method :current_usage, :billing_period_start
  end
end
